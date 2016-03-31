package main

/*
#cgo CFLAGS: -m64 -I C:/FTDI
#cgo LDFLAGS: -L. C:/FTDI/amd64/ftd2xx64.dll

#include "ftdiutil.h"
*/
import "C"

import (
	"bufio"
	"errors"
	"flag"
	"fmt"
	"html"
	"image"
	"image/color"
	"image/jpeg"
	"image/png"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"

	"github.com/nfnt/resize"
)

//GetImageFromFile : Will get image from file based on relative path.
//Retuns an array of bytes
func GetImageFromFile(filename string) (io.Reader, error, func() error) {
	r, err := os.Open(filename)
	return r, err, r.Close
}

//GetImageFromURL : Will download an image from the internet and return
//and array of bytes
func GetImageFromURL(url string) (io.Reader, error, func() error) {
	res, err := http.Get(url)
	if err != nil {
		return nil, err, nil
	}
	return res.Body, nil, res.Body.Close
}

// imageToByteBuffer : Takes an image and turns it into an array of RGBA color
func imageToByteBuffer(img image.Image) []color.Color {
	buffer := make([]color.Color, 256*256)
	b := img.Bounds()
	for y := b.Min.Y; y < b.Max.Y; y++ {
		for x := b.Min.X; x < b.Max.X; x++ {
			buffer[x+y*256] = img.At(x, y)
		}
	}
	//fmt.Println(buffer)
	return buffer
}

//clamp : Clamps between 0 and 7
func clamp(value uint32) uint32 {
	return uint32(value * 7 / 65535)
}

//colorToShort : Converts a RGBA color to an unsigned short only the lower 9
//bits have color informstion
func colorToShort(c color.Color) uint32 {
	red, green, blue, _ := c.RGBA()
	r := clamp(red)
	g := clamp(green)
	b := clamp(blue)

	return ((r << 6) | (g << 3) | b)

}

//colorToByteBuffer : converts and array of colors to an array of bytes
func colorToByteBuffer(colorBuffer []color.Color) []byte {
	buffer := make([]byte, len(colorBuffer)*2)
	for j := 0; j < len(buffer); j++ {
		buffer[j] = byte(0)
	}
	//Twobytes per color
	for i := 0; i < len(colorBuffer)-1; i++ {
		s := colorToShort(colorBuffer[i])
		buffer[2*i+1] = byte((s >> 8) & 0xff)
		buffer[2*i] = byte(s & 0xff)
	}
	//fmt.Println(buffer)
	return buffer
}

//sendImageToFTDI : sends the array of bytes to the FTDI for writing
func sendImageToFTDI(byteBuffer []byte) {
	var img *C.char = C.CString(string(byteBuffer))
	C.sendImage(img, C.int(len(byteBuffer)))
}

//SendByte : Sends a single byte to the FTDI
func SendByte(char byte) {
	C.sendChar(C.char(char))
}

// decodeImage : Takes an io Reader and tries to decode it given the fileType
func decodeImage(r io.Reader, fileType string) (image.Image, error) {
	fileType = strings.ToLower(fileType)
	switch fileType {

	default:
		img, codec, err := image.Decode(r)
		if err == nil {
			fmt.Printf("Decoded %s Image\n", codec)
			return img, err
		}
		fallthrough
	case "png":
		img, err := png.Decode(r)
		if err != nil {
			fmt.Println("Image is not a PNG")
		} else {
			fmt.Println("Decoded PNG Image")
			return img, err
		}
		fallthrough

	case "jpg":
		fallthrough
	case "jpeg":
		img, err := jpeg.Decode(r)
		if err != nil {
			fmt.Println("Image is not a JPEG")
		} else {
			fmt.Println("Decoded JPEG Image")
			return img, err
		}
	}
	return nil, errors.New("Could not Decode Image")
}

type randomDataMaker struct {
}

func (r *randomDataMaker) Read(p []byte) (n int, err error) {
	for i := range p {
		p[i] = byte(255 & 0xff)
	}
	return len(p), nil
}

//expects -usage -image or no flags. No flags sends one byte at a time to the FTDI
func main() {
	urlPtr := flag.String("image", "", `A URL to an image of a image file.
		Don't pass to enter single byte passing mode`)
	fileTypePtr := flag.String("type", "", "Type of image. Supports png and jpeg")
	usagePtr := flag.Bool("usage", false, "Print Usage Message")
	flag.Parse()

	//Prints the usage message.
	if *usagePtr {
		flag.Usage()
		return
	}

	//Prints Device Status
	if (C.getDevice()) == 0 {
		fmt.Println("Failed to get device status")
	} else {
		defer C.closeDevice()
	}

	//If no command line flags, send 1 byte at a time in loop back
	if *urlPtr == "" {
		//Assume loop back
		fmt.Println("Sending bytes 1 at a time. Type 'quit' to exit")
		fmt.Print(">>")
		scanner := bufio.NewScanner(os.Stdin)
		for scanner.Scan() {
			line := scanner.Bytes()
			if string(line) == "quit" {
				return
			}
			SendByte(line[0])
			fmt.Print(">>")

		}
	}

	reader, err, cleanup := GetImageFromFile(*urlPtr)
	if err != nil {
		fmt.Println("Could not find a file with this name, attempting to find url")
		_, urlErr := url.Parse(html.EscapeString(strings.TrimSpace(*urlPtr)))
		if urlErr == nil {
			reader, err, cleanup = GetImageFromURL(*urlPtr)
			if err != nil {
				fmt.Printf("Could not get image. %s", err.Error())
				return
			}
		} else {
			fmt.Printf("Could not interpret image as a url: %s. Reformat and try again.\n", urlErr.Error())
			return
		}
	}

	defer cleanup()

	image, imgErr := decodeImage(reader, *fileTypePtr)
	if imgErr != nil {
		fmt.Println(imgErr.Error())
		return
	}
	//fmt.Println(img)
	resized := resize.Resize(256, 256, image, resize.NearestNeighbor)
	fmt.Println(resized.Bounds())
	fmt.Println("Step 1: Resized Image")
	colorBuffer := imageToByteBuffer(resized)
	fmt.Println("Step 2: Get Color Data from Image")
	byteBuffer := colorToByteBuffer(colorBuffer)
	fmt.Println("Step 3: Format Color Data for FTDI len", len(byteBuffer))
	sendImageToFTDI(byteBuffer)
	fmt.Println("Step 4 SEND IMAGE TO FTDI")

}
