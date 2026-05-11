package push

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"

	"github.com/sideshow/apns2"
	"github.com/sideshow/apns2/payload"
	"github.com/sideshow/apns2/token"
)

type Client struct {
	apns     *apns2.Client
	bundleID string
}

func NewClient(keyB64, keyID, teamID, bundleID string, production bool) (*Client, error) {
	if keyB64 == "" {
		return nil, fmt.Errorf("APNS_KEY_BASE64 is empty")
	}
	keyBytes, err := base64.StdEncoding.DecodeString(keyB64)
	if err != nil {
		return nil, fmt.Errorf("decode apns key: %w", err)
	}
	authKey, err := token.AuthKeyFromBytes(keyBytes)
	if err != nil {
		return nil, fmt.Errorf("parse apns key: %w", err)
	}
	tk := &token.Token{
		AuthKey: authKey,
		KeyID:   keyID,
		TeamID:  teamID,
	}
	c := apns2.NewTokenClient(tk)
	if production {
		c = c.Production()
	} else {
		c = c.Development()
	}
	return &Client{apns: c, bundleID: bundleID}, nil
}

func (c *Client) Send(deviceToken, title, body string, data map[string]any) error {
	if c == nil {
		return nil
	}
	p := payload.NewPayload().
		AlertTitle(title).
		AlertBody(body).
		Sound("default").
		MutableContent()
	for k, v := range data {
		p = p.Custom(k, v)
	}
	n := &apns2.Notification{
		DeviceToken: deviceToken,
		Topic:       c.bundleID,
		Payload:     p,
	}
	res, err := c.apns.Push(n)
	if err != nil {
		return err
	}
	if !res.Sent() {
		raw, _ := json.Marshal(res)
		log.Printf("apns not sent: %s", string(raw))
		return fmt.Errorf("apns reject: %s", res.Reason)
	}
	return nil
}

func (c *Client) SendToTokens(tokens []string, title, body string, data map[string]any) {
	if c == nil {
		return
	}
	for _, t := range tokens {
		if err := c.Send(t, title, body, data); err != nil {
			log.Printf("apns send to %s: %v", t[:min(8, len(t))], err)
		}
	}
}
