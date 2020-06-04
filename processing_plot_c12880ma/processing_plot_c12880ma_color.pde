/*

Summary: Graphs data coming from the Hammamatsu C12880ma sensor, in this case sitting on a GroupGets breakout board.
This adds the following features to the original plotting code:
1 - Maps wavelenghts to RGB values and graphs in color
2 - Draws a white line for non visible spectra
3 - Accepts the calibration data for a given sensor, so the wavelengths should be accurate

Adopted from the groupgets sample code: https://github.com/groupgets/c12880ma
Wavelength to RGB code adapted from Roedy Green. https://wush.net/svn/mindprod/com/mindprod/wavelength/Wavelength.java

 */

import processing.serial.*;
import java.awt.Color;

Serial myPort;
String val;
int[]data;
// Using an arduino UNOs 10 bit ADC, our max analog value should be ~1024
// although max values seem to be around 1020 from the C12880MA
int displayHeight=1024;
int maxdata=0;

void setup(){
	println(Serial.list());
	String portName=Serial.list()[0]; //This is the index into the serial list, if you only have one serial device the index is 0
	myPort=new Serial(this,portName,115200);
	size(288,displayHeight);
	background(0);
}

void draw(){
	if(myPort.available()>0){
		val=myPort.readStringUntil('\n');         // read it and store it in val
		//val = "256,256,256,256,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,256,256,256,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,68,68,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,68,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,69,";
		if(val!=null){
			data=int(split(val,','));
			float wavelength=0;
			for(int i=0;i<data.length;i++){
				//if (data[i] > maxdata) {
				//  maxdata = data[i];
				//  println("Max Value: " + maxdata);
				//}
				wavelength=(float)getCalibratedWavelengthForPixel(i);

				Color myColor=wavelengthToColor(wavelength,1);
				//println("wavelength: " + wavelength);
				//println("rgb: " + myColor.getRed() + "," + myColor.getGreen() + "," + myColor.getBlue());

				stroke(myColor.getRed(),myColor.getGreen(),myColor.getBlue());
				// color spectrum line
				line(i-1,displayHeight-1,i,displayHeight-data[i]);


				// background line
				stroke(0,0,0);
				line(i,0,i,displayHeight-data[i]);

				// line for non visible spectrum wavelengths
				if(myColor.getRed()==0&myColor.getGreen()==0&myColor.getBlue()==0){
					stroke(255,255,255);
					point(i,displayHeight-(data[i]));
					//line(i,displayHeight-(data[i]),i,displayHeight-(data[i]));
				}
			}
		}
	}
}

// returns the light wavelength in nanometers given the pixel number and calibration data
public static double getCalibratedWavelengthForPixel(int pixel){
		double wavelength=0;
		// Calibration data
		double A0=3.05816373E+02;
		double B1=2.704519119;
		double B2=-1.24524592E-03;
		double B3=-6.240333348E-06;
		double B4=2.78880599E-09;
		double B5=1.47061294E-11;
		wavelength=A0+(B1*pixel)+(B2*Math.pow(pixel,2))+(B3*Math.pow(pixel,3))+(B4*Math.pow(pixel,4))+(B5*Math.pow(pixel,5));
		return wavelength;
		}


// returns an integer array with the R,G,B values for a given wavelength
public static Color wavelengthToColor(float wavelength,float gamma){
	/*
	 * red, green, blue component in range 0.0 .. 1.0.
	 */
	float r=0;
	float g=0;
	float b=0;
	/*
	 * intensity 0.0 .. 1.0
	 * based on drop off in vision at low/high wavelengths
	 */
	float s=1;
	/*
	 * We use different linear interpolations on different bands.
	 * These numbers mark the upper bound of each band.
	 * Wavelengths of the various bands.
	 */
	final float[]bands={380,420,440,490,510,580,645,700,780,Float.MAX_VALUE};
	/*
	 * Figure out which band we fall in.  A point on the edge
	 * is considered part of the lower band.
	 */
	int band=bands.length-1;
	for(int i=0;i<bands.length;i++){
		if(wavelength<=bands[i]){
		band=i;
		break;
		}
	}
	switch(band){
	case 0:
		/* invisible below 380 */
		// The code is a little redundant for clarity.
		// A smart optimiser can remove any r=0, g=0, b=0.
		r=0;
		g=0;
		b=0;
		s=0;
		break;
	case 1:
		/* 380 .. 420, intensity drop off. */
		r=(440-wavelength)/(440-380);
		g=0;
		b=1;
		s=.3f+.7f*(wavelength-380)/(420-380);
		break;
	case 2:
		/* 420 .. 440 */
		r=(440-wavelength)/(440-380);
		g=0;
		b=1;
		break;
	case 3:
		/* 440 .. 490 */
		r=0;
		g=(wavelength-440)/(490-440);
		b=1;
		break;
	case 4:
		/* 490 .. 510 */
		r=0;
		g=1;
		b=(510-wavelength)/(510-490);
		break;
	case 5:
		/* 510 .. 580 */
		r=(wavelength-510)/(580-510);
		g=1;
		b=0;
		break;
	case 6:
		/* 580 .. 645 */
		r=1;
		g=(645-wavelength)/(645-580);
		b=0;
		break;
	case 7:
		/* 645 .. 700 */
		r=1;
		g=0;
		b=0;
		break;
	case 8:
		/* 700 .. 780, intensity drop off */
		r=1;
		g=0;
		b=0;
		s=.3f+.7f*(780-wavelength)/(780-700);
		break;
	case 9:
		/* invisible above 780 */
		r=0;
		g=0;
		b=0;
		s=0;
		break;
	} // end switch
	// apply intensity and gamma corrections.
	s*=gamma;
	r*=s;
	g*=s;
	b*=s;
	return new Color(r,g,b);
} // end wavelengthToColor
