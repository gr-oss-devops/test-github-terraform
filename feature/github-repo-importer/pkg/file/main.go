package file

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

func WriteRepositoryToYAML(data []byte, repoName string) error {
	filename := fmt.Sprintf("%s.yaml", repoName)

	err := os.WriteFile(filename, data, 0644)
	if err != nil {
		return fmt.Errorf("failed to write YAML to file: %w", err)
	}

	return nil
}

func ImportFromFile(fileName string) error {
	if _, err := os.Stat(fileName); os.IsNotExist(err) {
		return fmt.Errorf("file %s does not exist", fileName)
	}

	fmt.Printf("Simulating processing repositories from file: %s\n", fileName)
	return nil
}

func DumpResponse(fileName string, repoName string, data interface{}) {
	jsonFileName := fileName + ".json"
	filePath := filepath.Join("./dumps", repoName, jsonFileName)

	fmt.Printf("Creating JSON file: %s\n", filePath)

	file, err := os.Create(filePath)
	if err != nil {
		fmt.Printf("error creating file: %v\n", err)
	}
	defer func(file *os.File) {
		err := file.Close()
		if err != nil {

		}
	}(file)

	jsonData, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		fmt.Printf("error marshaling response body to JSON: %v\n", err)
	}

	// Write the JSON data to the file
	_, err = file.Write(jsonData)
	if err != nil {
		fmt.Printf("error writing to file: %v\n", err)
	}

	fmt.Printf("JSON file created successfully: %s\n", filePath)
}

func CreateRepositoryDirectory(repoName string) {
	repoDir := filepath.Join("./dumps", repoName)
	err := os.MkdirAll(repoDir, os.ModePerm)
	if err != nil {
		fmt.Printf("error creating repository directory: %v", err)
	} else {
		fmt.Printf("Repository directory created: %s\n", repoDir)
	}
}

func CreateDumpsDirectory() {
	if _, err := os.Stat("./dumps"); os.IsNotExist(err) {
		err := os.Mkdir("./dumps", os.ModePerm)
		if err != nil {
			fmt.Printf("error creating dumps directory: %v", err)
		}
	}
}
