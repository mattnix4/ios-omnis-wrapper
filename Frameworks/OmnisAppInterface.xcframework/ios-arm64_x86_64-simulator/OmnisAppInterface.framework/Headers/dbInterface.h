
/* Changes
 Date       Edit        Fault       Description
 22-Jan-18	jmgFramework						Changes towards creating an Omnis iOS Framework
 05-Mar-15  jmg0204                 Moved UltraLite code out into Release Project.
 
 */

/*
 *  dbInterface.h
 *  Declares the public access functions to the database abstract layer
 *
 *  Created by Gary Ashford on 05/09/2012.
 *  Copyright 2017 Omnis Software Ltd. All rights reserved.
 *
 */

#ifndef SC_COMMS_H
#define SC_COMMS_H

#ifdef __cplusplus
extern "C" {
#endif
//dbInterfaceInit() must be called before dbInterfaceRequest().
//The first parameter is the pointer to a callback function
//conforming to the prototype as indicated.
//The second param is the database name.
//The third param is a pointer, which will be passed back through to the callback function.
//Creates the event monitoring thread & returns true if the monitoring thread was created successfully.
//Upon completion of a request, the callback function is called with a JSON string containing an identifier,
//an error info object and an object describing the result set (where applicable):
//{ ID:{}, Info:{}, ResultSet:{} }
//The second param tp the callback function will be the 'ref' passed through to the dbInterfaceInit.
//This can be used, for example, to pass a reference to the class handling the results, so when the callback is called, instance variables etc can be accessed.
//The return value of the callback function is currently ignored.
void* dbInterfaceInit(bool pCallbackFunc(char *, void*), const char *dbaseName, void *ref); // jmg0204 // jmgFramework

//dbInterfaceRequest() receives a new request from the wrapper.
//scInterfaceRequest takes a copy of the request, adds it to a queue, (blocking the caller momentarily) 
//before returning.
//(It is safe for the caller to destroy pRequestString upon return from scInterfaceRequest).
//Returns true if the request was successfully added to the queue.
bool dbInterfaceRequest(const char *pRequestString, void* pDbThreadStruct); // jmgFramework

//NB) Just as dbInterfaceRequest() is called on the wrapper thread, so pCallbackFunc is
//called on the monitoring thread. The callback function should therefore take a copy of the return data
//and add this to a queue so as to complete as quickly as possible.
//(The monitoring thread destroys the result data when it finishes processing each request).
	
bool dbInterfaceDestroy(void* pDbThreadStruct); // jmgFramework
	
#ifdef __cplusplus
}
#endif

#endif

