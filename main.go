package main

/*
#cgo CFLAGS: -m64 -I C:/FTDI
#cgo LDFLAGS: -L. C:/FTDI/amd64/ftd2xx64.dll

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "ftd2xx.h"
*/
import "C"

import (
	"bytes"
	"encoding/binary"
	"flag"
	"fmt"
	"image"
	"image/color"
	"image/jpeg"
	"image/png"
	"io/ioutil"
	"net/http"
	"net/url"
	"unsafe"

	"github.com/nfnt/resize"
)

func GetImageFromFile(filename string) []byte {
	dat, err := ioutil.ReadFile(filename)
	if err != nil {
		fmt.Println(err.Error())
		panic(err)
	}
	return dat
}

func GetImageFromURL(url string) []byte {
	res, err := http.Get(url)

	defer res.Body.Close()
	dat, err := ioutil.ReadAll(res.Body)
	if err != nil {
		fmt.Println(err.Error())
		panic(err)
	}
	return dat
}

func imageToByteBuffer(img image.Image) []color.Color {
	buffer := make([]color.Color, 256*256)
	b := img.Bounds()
	for y := b.Min.Y; y < b.Max.Y; y++ {
		for x := b.Min.X; x < b.Max.X; x++ {
			buffer[x+y*256] = img.At(x, y)
		}
	}
	return buffer
}

//Clamps between 0 and 7
func clamp(value uint32) uint32 {
	return uint32(value * 7 / 65535)
}

func colorToShort(c color.Color) uint16 {
	red, green, blue, _ := c.RGBA()
	r := clamp(red)
	g := clamp(green)
	b := clamp(blue)

	var color uint16 = uint16(r << 6 & g << 3 & b)
	return color
}

func colorToByteBuffer(colorBuffer []color.Color) []byte {
	buffer := new(bytes.Buffer)
	//Twobytes per color
	for _, c := range colorBuffer {
		err := binary.Write(buffer, binary.BigEndian, colorToShort(c))
		if err != nil {
			fmt.Println(err.Error())
			panic(err)
		}
	}
	return buffer.Bytes()
}

func sendImageToFTDI(byteBuffer []byte) {
	var ftHandle C.FT_HANDLE
	var ftStatus C.FT_STATUS
	var bytesWritten C.DWORD
	TxBuffer := (*C.char)(unsafe.Pointer(&byteBuffer[0]))

	ftStatus = C.FT_Open(0, unsafe.Pointer(&ftHandle))
	if ftStatus != C.FT_OK {
		fmt.Println("Failed to open device")
		return
	}

	ftStatus = C.FT_Write(ftHandle, TxBuffer, C.DWORD(unsafe.Sizeof(TxBuffer)), (*C.DWORD)(unsafe.Pointer(&bytesWritten)))
	if ftStatus != C.FT_OK {
		fmt.Println("Write Okay")
	} else {
		fmt.Println("Write Failed")
	}
	C.FT_Close(ftHandle)
}
func main() {
	fmt.Println("Step 0")
	urlPtr := flag.String("image", "", "A URL to an image of a image file")
	flag.Parse()

	if *urlPtr == "" {
		flag.Usage()
		return
	}
	var data []byte
	_, err := url.Parse(*urlPtr)
	if err != nil {
		data = GetImageFromFile(*urlPtr)
	} else {
		data = GetImageFromURL(*urlPtr)
	}
	// don't worry about errors
	reader := bytes.NewReader(data)
	img, imgErr := jpeg.Decode(reader)
	if imgErr != nil {
		img, imgErr = png.Decode(reader)
		if imgErr != nil {
			img, _, imgErr = image.Decode(reader)
			if imgErr != nil {
				fmt.Println(imgErr.Error())
				panic(err)
			}
		}
	}

	m := resize.Resize(256, 256, img, resize.Lanczos3)
	fmt.Println("Step 1")
	colorBuffer := imageToByteBuffer(m)
	fmt.Println("Step 2")
	byteBuffer := colorToByteBuffer(colorBuffer)
	fmt.Println("Step 3", len(byteBuffer))
	sendImageToFTDI(byteBuffer)
	fmt.Println("Step 4")

}
