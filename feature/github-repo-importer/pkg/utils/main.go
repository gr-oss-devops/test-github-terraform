package utils

import (
	"os"
)

// FileExists checks if a file exists
func FileExists(fileName string) bool {
	_, err := os.Stat(fileName)
	return err == nil
}
