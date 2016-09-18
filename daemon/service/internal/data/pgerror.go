package data

import (
	"fmt"
	"math"
	"time"

	"github.com/lib/pq"
)

var NegativeInfinityTS = time.Date(math.MinInt32, time.January, 1, 0, 0, 0, 0, time.UTC)
var PositiveInfinityTS = time.Date(math.MaxInt32, time.December, 31, 23, 59, 59, 1e9-1, time.UTC)

func init() {
	pq.EnableInfinityTs(NegativeInfinityTS, PositiveInfinityTS)
}

type pgError struct {
	message string
	code    string
}

// newError creates a DBError from a pq.Error
func newError(err error) DBError {
	if err == nil {
		return nil
	}
	// convert to pq.Error and extract fields
	if pqErr, ok := err.(*pq.Error); ok {
		return &pgError{message: pqErr.Message, code: string(pqErr.Code)}
	}
	// Use error string
	return &pgError{message: err.Error(), code: "00000"}
}

func (e *pgError) Error() string {
	return fmt.Sprintf("%s: %s", e.Code(), e.Message())
}

func (e *pgError) Code() string {
	return e.code
}

func (e *pgError) Message() string {
	return e.message
}
