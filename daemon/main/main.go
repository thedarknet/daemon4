package main

import (
	"fmt"
	"log"
	"os"

	"github.com/thedarknet/daemon4/daemon/service"
	"github.com/thedarknet/daemon4/http-problem"
)

func getPostgresqlConnection() string {
	return fmt.Sprintf("postgres://%s:%s@%s/%s?sslmode=disable", os.Getenv("POSTGRESQL_SERVICE_USER"), os.Getenv("POSTGRESQL_SERVICE_PASSWORD"), os.Getenv("POSTGRESQL_SERVICE_HOST"), os.Getenv("POSTGRESQL_SERVICE_DB"))
}

func main() {
	log.Printf("Starting daemon")
	// TODO lock behind config
	problem.Verbose = true
	service.ListenAndServe(getPostgresqlConnection())
}
