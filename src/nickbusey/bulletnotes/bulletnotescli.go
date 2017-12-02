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

	homedir "github.com/mitchellh/go-homedir"
	"github.com/russross/blackfriday"
	"github.com/spf13/viper"
)

const (
	// apiUrl string = "http://localhost:3123/bot/chat"
	apiUrl string = "https://bulletnotes.io/bot/chat"
)


func check(e error) {
    if e != nil {
        panic(e)
    }
}

func chatLoop(apiKey string) {
	reader := bufio.NewReader(os.Stdin)
	fmt.Print("\u001b[38;5;84m > ")
	text, _ := reader.ReadString('\n')
	fmt.Println("\u001b[0m")

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

		renderer := &Console{}
		extensions := 0 |
			blackfriday.EXTENSION_NO_INTRA_EMPHASIS |
			blackfriday.EXTENSION_FENCED_CODE |
			blackfriday.EXTENSION_AUTOLINK |
			blackfriday.EXTENSION_STRIKETHROUGH |
			blackfriday.EXTENSION_SPACE_HEADERS |
			blackfriday.EXTENSION_HEADER_IDS |
			blackfriday.EXTENSION_BACKSLASH_LINE_BREAK |
			blackfriday.EXTENSION_DEFINITION_LISTS


		scanner := bufio.NewScanner(strings.NewReader(string(data)))
		for scanner.Scan() {			
			os.Stdout.Write(blackfriday.Markdown([]byte(scanner.Text()), renderer, extensions))
		}
		if err := scanner.Err(); err != nil {
			fmt.Println(err)
		}

		chatLoop(apiKey)
	}
}

func main() {
	reader := bufio.NewReader(os.Stdin)
	fmt.Println("\n\u001b[1m\u001b[38;5;87m < Welcome to BulletNotesBot!")
	fmt.Println("")

	viper.SetConfigName("cli") // name of config file (without extension)
	dir, _ := homedir.Dir()
	viper.AddConfigPath(dir+"/.bulletnotes")  // call multiple times to add many search paths
	viper.AddConfigPath(".")               // optionally look for config in the working directory
	err := viper.ReadInConfig() // Find and read the config file
	if err != nil { // Handle errors reading the config file
		fmt.Print("\u001b[38;5;84m > Enter your BulletNotes API Key (available at https://bulletnotes.io/settings): ")
		apiKey, _ := reader.ReadString('\n')

		v := url.Values{}
		v.Set("chat", "/help")
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
			fmt.Println("\n\u001b[31;1m * Bad API Key. Please generate a new one at https://bulletnotes.io/settings\n\u001b[0m")
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode == 200 {
			os.MkdirAll(dir+"/.bulletnotes", os.ModePerm);

	    d1 := []byte("apiKey: "+apiKey)
	    err := ioutil.WriteFile(dir+"/.bulletnotes/cli.yaml", d1, 0644)
	    check(err)

			fmt.Println("\n\u001b[38;5;84m < Authorization successful! Alright, send me a note to record, or type /help for more information.\n")
			chatLoop(apiKey)
		} else {
			fmt.Println("Bad api key...")
		}
	} else {
		chatLoop(viper.GetString("apiKey"))
	}
}