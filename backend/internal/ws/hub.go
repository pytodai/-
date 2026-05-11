package ws

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/coder/websocket"
	"github.com/redis/go-redis/v9"
)

const (
	pingInterval = 30 * time.Second
	writeTimeout = 10 * time.Second
	channelName  = "status_updates"
)

type Message struct {
	Type   string `json:"type"`
	UserID string `json:"user_id,omitempty"`
	Data   any    `json:"data,omitempty"`
}

type client struct {
	conn   *websocket.Conn
	userID string
	send   chan []byte
}

type Hub struct {
	mu      sync.RWMutex
	clients map[string][]*client // userID -> clients
	rdb     *redis.Client
}

func NewHub(rdb *redis.Client) *Hub {
	return &Hub{
		clients: make(map[string][]*client),
		rdb:     rdb,
	}
}

func (h *Hub) Run(ctx context.Context) {
	sub := h.rdb.Subscribe(ctx, channelName)
	defer sub.Close()
	ch := sub.Channel()
	for {
		select {
		case <-ctx.Done():
			return
		case msg, ok := <-ch:
			if !ok {
				return
			}
			h.broadcast([]byte(msg.Payload))
		}
	}
}

func (h *Hub) Publish(ctx context.Context, msg Message) error {
	data, err := json.Marshal(msg)
	if err != nil {
		return err
	}
	return h.rdb.Publish(ctx, channelName, data).Err()
}

func (h *Hub) broadcast(data []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()
	for _, clients := range h.clients {
		for _, c := range clients {
			select {
			case c.send <- data:
			default:
			}
		}
	}
}

func (h *Hub) register(c *client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.clients[c.userID] = append(h.clients[c.userID], c)
}

func (h *Hub) unregister(c *client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	list := h.clients[c.userID]
	for i, cl := range list {
		if cl == c {
			h.clients[c.userID] = append(list[:i], list[i+1:]...)
			break
		}
	}
	if len(h.clients[c.userID]) == 0 {
		delete(h.clients, c.userID)
	}
}

func (h *Hub) ServeWS(userID string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		conn, err := websocket.Accept(w, r, &websocket.AcceptOptions{
			InsecureSkipVerify: true,
		})
		if err != nil {
			log.Printf("ws accept: %v", err)
			return
		}

		c := &client{conn: conn, userID: userID, send: make(chan []byte, 64)}
		h.register(c)
		defer func() {
			h.unregister(c)
			conn.Close(websocket.StatusNormalClosure, "")
		}()

		ctx := r.Context()
		go h.writePump(ctx, c)
		h.readPump(ctx, c)
	}
}

func (h *Hub) writePump(ctx context.Context, c *client) {
	ticker := time.NewTicker(pingInterval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case msg := <-c.send:
			wCtx, cancel := context.WithTimeout(ctx, writeTimeout)
			err := c.conn.Write(wCtx, websocket.MessageText, msg)
			cancel()
			if err != nil {
				return
			}
		case <-ticker.C:
			wCtx, cancel := context.WithTimeout(ctx, writeTimeout)
			err := c.conn.Ping(wCtx)
			cancel()
			if err != nil {
				return
			}
		}
	}
}

func (h *Hub) readPump(ctx context.Context, c *client) {
	for {
		_, _, err := c.conn.Read(ctx)
		if err != nil {
			return
		}
	}
}
