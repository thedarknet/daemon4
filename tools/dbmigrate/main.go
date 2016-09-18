package main

import (
	"database/sql"
	"flag"
	"fmt"
	"log"

	"github.com/howeyc/gopass"
	_ "github.com/lib/pq"
)

func main() {
	host := flag.String("h", "localhost", "Postresql hostname")
	port := flag.Int("p", 5432, "Postgresql port")
	dbName := flag.String("d", "postgres", "Postgresql database name")
	user := flag.String("u", "postgres", "Username used for migration")
	passwd := flag.String("P", "password", "Password for migration user")
	ssl := flag.String("s", "disable", "SSL mode to use when conneting to database")
	prompt := flag.Bool("W", false, "Prompt for migration user password")
	file := flag.String("f", "migrate.json", "JSON file containing migration definition")
	clear := flag.Bool("c", false, "Clear database. Removes all objects owned by migration user")

	flag.Parse()

	// Get interactive password
	if *prompt {
		fmt.Printf("Enter Password: ")
		bp, err := gopass.GetPasswd()
		if err != nil {
			fmt.Println("")
			log.Fatalf("Error reading password: (%v)", err)
		}
		*passwd = string(bp)
	}

	log.Printf("Connecting to %s:%d/%s as %s", *host, *port, *dbName, *user)
	db, err := testDBConnection(*host, *port, *dbName, *user, *passwd, *ssl)
	if err != nil {
		log.Fatalf("Error connecting to db: (%v)", err)
	}

	m, err := Load(db, *file)
	if err != nil {
		log.Fatalf("Unable to load migration definition: (%v)", err)
	}

	if *clear {
		log.Println("Clearing database")
		err = m.Clear(*user)
		if err != nil {
			log.Fatalf("Unable to clear database: (%v)", err)
		}
	}

	err = m.Migrate()
	if err != nil {
		log.Fatalf("Unable to migrate database: (%v)", err)
	}
}

func testDBConnection(host string, port int, dbName string, user string, password string, ssl string) (*sql.DB, error) {
	connStr := fmt.Sprintf("postgres://%s:%s@%s:%d/%s?sslmode=%s", user, password, host, port, dbName, ssl)
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, err
	}
	_, err = db.Exec("SELECT 1")
	return db, err
}
