/*
* 	Genome2D - GPU 2D framework utilizing Molehill API
*
*	Copyright 2011 Peter Stefcek. All rights reserved.
*
*	License:: ./doc/LICENSE.md (https://github.com/pshtif/Genome2D/blob/master/LICENSE.md)
*/
package com.genome2d.assets;

import haxe.Http;
import js.html.ImageElement;
import js.html.Event;
import js.Browser;

class GImageAsset extends GAsset {
    public var g2d_nativeImage:ImageElement;

    override public function load():Void {
		g2d_nativeImage = Browser.document.createImageElement();
		g2d_nativeImage.onload = loadedHandler;
		g2d_nativeImage.src = g2d_url;
    }

    private function loadedHandler(event:Event):Void {
        g2d_loaded = true;
        onLoaded.dispatch(this);
    }
}
