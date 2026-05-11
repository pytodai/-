package geocode

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"time"
)

type nominatimResponse struct {
	Address struct {
		Suburb   string `json:"suburb"`
		Quarter  string `json:"quarter"`
		District string `json:"district"`
		City     string `json:"city"`
	} `json:"address"`
}

var httpClient = &http.Client{Timeout: 5 * time.Second}

// ReverseGeocode returns the district/suburb name for the given coordinates.
// Returns empty string on any error so callers can proceed without a district.
func ReverseGeocode(ctx context.Context, lat, lon float64) string {
	params := url.Values{}
	params.Set("lat", fmt.Sprintf("%f", lat))
	params.Set("lon", fmt.Sprintf("%f", lon))
	params.Set("format", "json")
	params.Set("addressdetails", "1")
	params.Set("zoom", "14")

	req, err := http.NewRequestWithContext(ctx, http.MethodGet,
		"https://nominatim.openstreetmap.org/reverse?"+params.Encode(), nil)
	if err != nil {
		return ""
	}
	req.Header.Set("User-Agent", "SvobodeniOS/1.0")

	resp, err := httpClient.Do(req)
	if err != nil {
		return ""
	}
	defer resp.Body.Close()

	var nr nominatimResponse
	if err := json.NewDecoder(resp.Body).Decode(&nr); err != nil {
		return ""
	}

	switch {
	case nr.Address.Suburb != "":
		return nr.Address.Suburb
	case nr.Address.Quarter != "":
		return nr.Address.Quarter
	case nr.Address.District != "":
		return nr.Address.District
	default:
		return nr.Address.City
	}
}
