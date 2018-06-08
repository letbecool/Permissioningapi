package main

import (
	"encoding/json"
	"log"
	"fmt"
	"net/http"
	"io/ioutil"
	"github.com/gorilla/mux"
)

///*
type Node struct {
	Enode string   `json:"enode,omitempty"`

}
func sendToServer2(w http.ResponseWriter, req *http.Request) {
	data := "1234";
	json.NewEncoder(w).Encode(&Node{data})

}

type Node2 struct {
	Enode string `json:"enode,omitempty"`

}
var results string
var node2 Node2
func receivefromServer2(w http.ResponseWriter, r *http.Request) {

	if r.Method == "POST" {
		body, err := ioutil.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Error reading request body",
				http.StatusInternalServerError)
		}

		//fmt.Fprintf(w, string(body))
		//node2.Enode = body
		//fmt.Fprintf(w, node2.Enode)
		//Now the data received from the server2
		results = string(body)
		fmt.Println(results)
		fmt.Fprintf(w, string(body))
		fmt.Fprintf(w, results)
		fmt.Fprint(w, "POST done")
	} else {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
	}

}

func main() {
	router := mux.NewRouter()


	router.HandleFunc("/nodedetails", sendToServer2).Methods("GET")
	router.HandleFunc("/noderesponse", receivefromServer2).Methods("POST")

	log.Fatal(http.ListenAndServe("localhost:5000", router))


}
