package main

import (
  "bufio"
  "fmt"
	"io/ioutil"
  "os"
  "net/http"
  "net/url"
	"strings"
  "crypto/tls"
)

const (
	// apiUrl string = "http://localhost:3123/bot/chat"
	apiUrl string = "https://bulletnotes.io/bot/chat"
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

  tr := &http.Transport{
  	// Oh bad, naughty, wicked Zoot!
    TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
  }
  c := &http.Client{Transport: tr}
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