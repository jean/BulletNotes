package main

import (
  "bufio"
  "fmt"
	"io/ioutil"
  "os"
  "net/http"
  "net/url"
	"strings"
)

const (
	apiUrl string = "http://localhost:3123/bot/chat"
)

func chatLoop(apiKey string) {
	reader := bufio.NewReader(os.Stdin)
	fmt.Print("> ")
	text, _ := reader.ReadString('\n')
	fmt.Println(text)

	v := url.Values{}
	v.Set("chat", text)
	v.Set("apiKey", apiKey)

	s := v.Encode()
	req, err := http.NewRequest("POST", apiUrl, strings.NewReader(s))
	if err != nil {
		fmt.Printf("http.NewRequest() error: %v\n", err)
		return
	}

	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	c := &http.Client{}
	resp, err := c.Do(req)
	if err != nil {
		fmt.Printf("http.Do() error: %v\n", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode == 500 {
		fmt.Println("Server error.")
	} else {
		data, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			fmt.Printf("ioutil.ReadAll() error: %v\n", err)
			return
		}

		fmt.Printf("%v\n\n", string(data))


		chatLoop(apiKey)
	}
}

func main() {
	reader := bufio.NewReader(os.Stdin)
	fmt.Println("< Welcome to BulletNotesBot!")
	fmt.Println("")
	fmt.Print("Enter your BulletNotes API Key: ")
	apiKey, _ := reader.ReadString('\n')

	chatLoop(apiKey)
}