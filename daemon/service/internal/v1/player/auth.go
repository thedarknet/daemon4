package player

import (
	"crypto/hmac"
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"strconv"
	"strings"
)

//validateAuthToken checks auth tokens to ensure they are valid and signed properly.
//All tokens should be in the format: darknetID#externalAcct#hmacSig
func validateAuthToken(token string, accountID int64, hmacKey string) error {
	partials := strings.Split(token, "#")
	if len(partials) != 3 {
		return fmt.Errorf("Wrong number of fields in auth token. Expected 3, got %d", len(partials))
	}

	// ensure account id matches
	testID, err := strconv.ParseInt(partials[0], 0, 64)
	if err != nil {
		return fmt.Errorf("Unable to parse account id: (%v)", err)
	}

	if testID != accountID {
		return fmt.Errorf("Token is for wrong account. Expected %d, got %d", accountID, testID)
	}

	sig, err := hex.DecodeString(partials[2])
	if err != nil {
		return fmt.Errorf("Invalid sig, must be hex encoded")
	}

	hashString := fmt.Sprintf("%s#%s", partials[0], partials[1])
	mac := hmac.New(md5.New, []byte(hmacKey))
	mac.Write([]byte(hashString))
	expected := mac.Sum(nil)

	if !hmac.Equal(expected, sig) {
		return fmt.Errorf("Token is not properly signed")
	}
	return nil
}
