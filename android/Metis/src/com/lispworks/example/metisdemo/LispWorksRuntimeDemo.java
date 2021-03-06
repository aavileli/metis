/*
** $Header: /hope/lwhope1-cam/hope.0/compound/23/LISPexamples/RCS/android:MetisDemo:src:com:lispworks:example:metisdemo:LispWorksRuntimeDemo.java,v 1.1.1.1 2014/05/27 20:55:54 davef Exp $
**
** Copyright (c) 1987--2015 LispWorks Ltd. All rights reserved.
*/

package com.lispworks.example.metisdemo;

// SplashScreen
// An activity to display a splash screen.
// What is actually displayed is defined in the splash layout (res/layout/splash.xml
// It displays the layout and then initialize LispWorks and starts a timer
// for MINIMUM_TIME milliseconds. It starts the Metis game when both of these
// finished, so the splash screen is displayed for a minimum time of 
// MINIMUM_TIME milliseconds, but as much as needed if initialization is slow.
// With the Metis demo that should never happen, but more complex applications
// may take time to initialize. 

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;

 
import android.app.Activity;

public class LispWorksRuntimeDemo extends Activity {
	// We force the splash screen to be on for at least this time in milliseconds.
	private static final int MINIMUM_TIME = 1000;
	private static boolean can_go = false ; 
	@Override
    protected void onCreate(Bundle savedInstanceState) {
		 super.onCreate(savedInstanceState);
		if (can_go) 
			startMetisDemo() ; // application already started, skip the splash screen 
		else { 
       		setContentView(R.layout.splash); // show the splash screen 
        
			tryInit() ;    // initialize LispWorks
        
			// Start a timer for MINIMUM_TIME milliseconds. 
			new Handler().postDelayed(new Runnable() {
 
				@Override
				public void run() {
					maybeStartMetis() ; 
				}
              
			}, MINIMUM_TIME);
        
		}  
    
	}
	// maybeStartMetis
	// This starts the Metis game the second time it is called, which will be
	// the later of the call from the timer above and the call from tryInit (when 
	// LispWorks is ready or got an error) below.
	// Synchronized because we set and test can_go. Not obviously needed,
	// because really both calls should be on the main thread
	private synchronized void maybeStartMetis () {
    	if (can_go)  // The other call already went through here
    		startMetisDemo() ; 
    	else can_go = true; 
    }
	
	// tryInit
	// Initialize LispWOrks using the the interface from com.lispworks.Manager
	private void tryInit (){
		int lwStatus = com.lispworks.Manager.status ()  ; 
		switch (lwStatus) { 
		case com.lispworks.Manager.STATUS_READY : maybeStartMetis() ; break; 
		case com.lispworks.Manager.STATUS_ERROR : maybeStartMetis() ; break ; // The code in Metis.setupAndInit will give the error. 
		case com.lispworks.Manager.STATUS_INITIALIZING : 
		case  com.lispworks.Manager.STATUS_NOT_INITIALIZED :
			// Initialize with a runnable that will get called when LispWorks
			// finished to initialize (or got an error) and will run this method again 
		    Runnable rn = new Runnable () { public void run() { tryInit () ; } };
		    com.lispworks.Manager.init(this, rn);
			break ; 
		}
		
	}
	// Srart the Metis game by starting the activity Metis. 
    void startMetisDemo() {
          
        Intent metis_intent = new Intent(LispWorksRuntimeDemo.this, Metis.class);
        startActivity(metis_intent);

        finish(); 
        	        
        }
   }
