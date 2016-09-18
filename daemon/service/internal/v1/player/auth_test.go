package player

import (
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestUnit_HMAC(t *testing.T) {
	tests := []struct {
		Token         string
		AccountID     int64
		Key           string
		ExpectedError string
	}{
		{
			Token:     "1#1#cb6c0e823aa884644df1722cbeb7859b",
			AccountID: 1,
			Key:       "himan",
		},
		{
			Token:     "1#2#016f65acc1abb0d763d88cede96b31ab",
			AccountID: 1,
			Key:       "himan",
		},
		{
			Token:     "1#1#c856db9d3399b6cc2e7894aed7f3da3e",
			AccountID: 1,
			Key:       "byemanman",
		},
		{
			Token:     "1#2#099e0124bb87fb385d17bc92b60f642f",
			AccountID: 1,
			Key:       "byemanman",
		},
		{
			Token:         "2#099e0124bb87fb385d17bc92b60f642f",
			ExpectedError: "Wrong number of fields in auth token. Expected 3, got 2",
		},
		{
			Token:         "aaa#2#099e0124bb87fb385d17bc92b60f642f",
			ExpectedError: "Unable to parse account id: (strconv.ParseInt: parsing \"aaa\": invalid syntax)",
		},
		{
			Token:         "5#2#099e0124bb87fb385d17bc92b60f642f",
			AccountID:     1,
			ExpectedError: "Token is for wrong account. Expected 1, got 5",
		},
		{
			Token:         "1#2#zzz",
			AccountID:     1,
			ExpectedError: "Invalid sig, must be hex encoded",
		},
		{
			Token:         "1#2#099e0124bb87fb385d17bc92b60f642f",
			AccountID:     1,
			Key:           "notkey",
			ExpectedError: "Token is not properly signed",
		},
	}
	for idx, tt := range tests {
		t.Log("Starting tests %d/%d", idx+1, len(tests))

		err := validateAuthToken(tt.Token, tt.AccountID, tt.Key)
		if len(tt.ExpectedError) != 0 {
			assert.EqualError(t, err, tt.ExpectedError)
		} else {
			assert.Nil(t, err)
		}

	}
}
