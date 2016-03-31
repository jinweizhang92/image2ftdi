#ifndef FTDIUTIL_H
#define FTDIUTIL_H

#include "ftd2xx.h"

  BOOL getDevice(void);
  void getDeviceInfo();
  int sendChar(char key);
  void sendImage(char* image, int len);
  void closeDevice();
#endif
