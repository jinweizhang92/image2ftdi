
#include <windows.h>
#include <stdio.h>
#include "FTD2XX.h"
FT_HANDLE ftHandle; // valid handle returned from FT_OpenEx
FT_DEVICE ftDevice;
DWORD deviceID;
char SerialNumber[16];
char Description[64];
BOOL getDevice(void)
{
	FT_STATUS ftStatus; DWORD numDevs=0;
	FT_DEVICE_LIST_INFO_NODE *devInfo;
	int i;
	ftStatus = FT_CreateDeviceInfoList(&numDevs);
	if (numDevs > 0) { // allocate storage for list based on numDevs
		devInfo = (FT_DEVICE_LIST_INFO_NODE*) malloc(sizeof(FT_DEVICE_LIST_INFO_NODE)*numDevs);
		ftStatus = FT_GetDeviceInfoList(devInfo,&numDevs);
		if (ftStatus == FT_OK) { for (i = 0; i < numDevs; i++) {
			printf("Dev %d:\n",i);
			printf(" Flags=0x%x\n",devInfo[i].Flags);
			printf(" Type=0x%x\n",devInfo[i].Type);
			printf(" ID=0x%x\n",devInfo[i].ID);
			printf(" LocId=0x%x\n",devInfo[i].LocId);
			printf(" SerialNumber=%s\n",devInfo[i].SerialNumber);
			printf(" Description=%s\n",devInfo[i].Description);
			printf(" ftHandle=0x%x\n",devInfo[i].ftHandle); } }
		}
		char initializeString[] =  "FT2232H MiniModule A";
		ftStatus = FT_OpenEx((void *)initializeString, FT_OPEN_BY_DESCRIPTION, &ftHandle);
		if (ftStatus != FT_OK) { printf("Failed to open device.\n"); return FALSE;
	}
	ftStatus = FT_SetBitMode(ftHandle, 0xff, 0x00); // reset
	Sleep(10);
	ftStatus = FT_SetBitMode(ftHandle, 0x00, 0x40);
	if (ftStatus != FT_OK) { printf("Failed to set Bit Mode.\n"); return FALSE;
}
ftStatus = FT_SetTimeouts(ftHandle, 500, 500);
if (ftStatus != FT_OK) { printf("Failed to set timeouts.\n"); return FALSE;
}
ftStatus = FT_SetUSBParameters(ftHandle, 64*1024, 512);
if (ftStatus != FT_OK) { printf("Failed to set USB parameters.\n"); return FALSE;
}
ftStatus = FT_SetLatencyTimer(ftHandle, 100);
if (ftStatus != FT_OK) { printf("Failed to set latency timer.\n"); return FALSE;
}
ftStatus = FT_SetFlowControl(ftHandle,FT_FLOW_RTS_CTS,0,0);
if (ftStatus != FT_OK) { printf("Failed to set flow control.\n"); return FALSE;
}
// deviceID contains encoded device ID
// SerialNumber, Description contain 0-terminated strings
ftStatus = FT_GetDeviceInfo( ftHandle, &ftDevice, &deviceID, SerialNumber, Description, NULL );
	if (ftStatus == FT_OK) { return TRUE;
	} else { return FALSE;
	}
}
int main(int argc, char* argv[])
{
	char key; UCHAR txBuffer[2048]; // transmit buffer
	UCHAR rxBuffer[1024*64]; // received buffer
	int bytesWritten, bytesReceived;
	int sz;
	FT_STATUS ftStatus;
	txBuffer[0] = 0;
	printf("Getting Device Status...\n");
	if (!getDevice()) { printf("Error getting device status.\n"); scanf("%c", &key); return -1;
}
printf("\n\nftHandle:\t%d\nftDevice:\t%d\nSN:\t%s\nDesc:\t%s\n\n", ftHandle, ftDevice, SerialNumber, Description);
printf("Hit 't' key to toggle the lsb.\n");
printf("Hit 'x' to exit.\n\n");
sz = sizeof(rxBuffer);
while (TRUE) { key = getchar(); switch (key) {
	case 'x': return 0;
	break;
	case 't': ftStatus = FT_Write (ftHandle, txBuffer, 1, &bytesWritten );
	if (ftStatus != FT_OK) { printf("Error: could not write byte.\n");
	return -1; }
	printf("Wrote %d bytes.\n", bytesWritten);
	txBuffer[0] = !txBuffer[0];
	ftStatus = FT_Read(ftHandle, rxBuffer, 1, &bytesReceived);
	if ((ftStatus != FT_OK) || (bytesReceived != 1)) {
		printf("Error: could not read byte.\n");
		//
		return -1;
	} else {
		printf("Byte returned: 0x%02X\n",rxBuffer[0]);
	}
	break;
	default: ;
}
}
}
