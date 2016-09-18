package problem

import (
	"encoding/json"
	"net/http"
)

var (
	// Verbose when set to true will output the inner error parameter to the output.
	// This should be set to false for any public facing apis to prevent leaking security
	// information.
	Verbose bool
)

// problem is a helper struct for json encoding
type problem struct {
	Status   string  `json:"status"`
	Title    string  `json:"title"`
	Detail   string  `json:"detail"`
	Code     *string `json:"code,omitempty"`
	InnerErr *string `json:"inner,omitempty"`
}

// Write writes a json representation of an http-problem (http://tools.ietf.org/html/draft-nottingham-http-problem-06) to the
// response writer. The standard status, title, and detail fields will be written verbatim. Code should be a machine readable error
// code for other services to read and react to without needing to parse the human readable title or detail. innerErr should contain
// the error that caused the problem, it will be written to a "inner" field in the response if Verbose is set to true
func Write(w http.ResponseWriter, status int, title string, detail string, code string, innerErr error) {
	w.Header().Set("Content-Type", "application/problem+json")
	w.WriteHeader(status)

	p := &problem{
		Status: http.StatusText(status),
		Title:  title,
		Detail: detail,
	}

	if len(code) != 0 {
		p.Code = &code
	}

	if Verbose && innerErr != nil {
		str := innerErr.Error()
		p.InnerErr = &str
	}

	json.NewEncoder(w).Encode(p)
}
