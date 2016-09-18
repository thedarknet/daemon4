package main

import (
	"fmt"
	"log"
	"os"

	"github.com/thedarknet/daemon4/http-problem"
	"github.com/thedarknet/daemon4/remotes/badge/service"
)

func getPostgresqlConnection() string {
	return fmt.Sprintf("postgres://%s:%s@%s/%s?sslmode=disable", os.Getenv("POSTGRESQL_SERVICE_USER"), os.Getenv("POSTGRESQL_SERVICE_PASSWORD"), os.Getenv("POSTGRESQL_SERVICE_HOST"), os.Getenv("POSTGRESQL_SERVICE_DB"))
}

func main() {
	log.Printf("Starting badge")
	// TODO lock behind config
	problem.Verbose = true
	service.ListenAndServe(getPostgresqlConnection())
}
