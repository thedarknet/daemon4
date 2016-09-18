package msg

import (
	"errors"
)

var (
	ErrPlayerOnline  = errors.New("Player already online")
	ErrPlayerOffline = errors.New("Player is offline")
	ErrCancelled     = errors.New("Processing cancelled")
	ErrEOF           = errors.New("Unexpected EOF")
)
