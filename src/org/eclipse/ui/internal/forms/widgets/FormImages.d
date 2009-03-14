/*******************************************************************************
 * Copyright (c) 2007, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/
module org.eclipse.ui.internal.forms.widgets.FormImages;

//import org.eclipse.ui.internal.forms.widgets.FormImages;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.RGB;
import org.eclipse.swt.widgets.Display;

import java.lang.all;
import java.util.HashMap;
import java.util.Set;

public class FormImages {
    private static FormImages instance;

    public static FormImages getInstance() {
        if (instance is null)
            instance = new FormImages();
        return instance;
    }

    private HashMap images;
    private HashMap ids;

    private this() {
    }

    private abstract class ImageIdentifier {
        Display fDisplay;
        RGB[] fRGBs;
        int fLength;

        this(Display display, Color[] colors, int length) {
            fDisplay = display;
            fRGBs = new RGB[colors.length];
            for (int i = 0; i < colors.length; i++) {
                Color color = colors[i];
                fRGBs[i] = color is null ? null : color.getRGB();
            }
            fLength = length;
        }

        public bool equals(Object obj) {
            if (null !is cast(ImageIdentifier)obj ) {
                ImageIdentifier id = cast(ImageIdentifier)obj;
                if (id.fRGBs.length is fRGBs.length) {
                    bool result = id.fDisplay.opEquals(fDisplay) && id.fLength is fLength;
                    for (int i = 0; i < fRGBs.length && result; i++) {
                        result = result && id.fRGBs[i].opEquals(fRGBs[i]);
                    }
                    return result;
                }
            }
            return false;
        }

        public override hash_t toHash() {
            int hash = fDisplay.toHash();
            for (int i = 0; i < fRGBs.length; i++)
                hash = hash * 7 + fRGBs[i].toHash();
            hash = hash * 7 + fLength;
            return hash;
        }
    }

    private class SimpleImageIdentifier : ImageIdentifier{
        private int fTheight;
        private int fMarginHeight;

        this (Display display, Color color1, Color color2,
                int realtheight, int theight, int marginHeight) {
            super(display, [color1, color2], realtheight);
            fTheight = theight;
            fMarginHeight = marginHeight;
        }

        public bool equals(Object obj) {
            if (null !is cast(SimpleImageIdentifier)obj ) {
                SimpleImageIdentifier id = cast(SimpleImageIdentifier) obj;
                if (super.equals(obj)  &&
                        id.fTheight is fTheight && id.fMarginHeight is fMarginHeight)
                    return true;
            }
            return false;
        }

        public override hash_t toHash() {
            int hash = super.toHash();
            hash = hash * 7 + (new Integer(fTheight)).toHash();
            hash = hash * 7 + (new Integer(fMarginHeight)).toHash();
            return hash;
        }
    }

    private class ComplexImageIdentifier : ImageIdentifier {
        RGB fBgRGB;
        bool fVertical;
        int[] fPercents;

        public this(Display display, Color[] colors, int length,
                int[] percents, bool vertical, Color bg) {
            super(display, colors, length);
            fBgRGB = bg is null ? null : bg.getRGB();
            fVertical = vertical;
            fPercents = percents;
        }

        public bool equals(Object obj) {
            if (null !is cast(ComplexImageIdentifier)obj ) {
                ComplexImageIdentifier id = cast(ComplexImageIdentifier) obj;
                if (super.equals(obj)  &&
                        id.fVertical is fVertical && ArrayEquals(id.fPercents, fPercents)) {
                    if ((id.fBgRGB is null && fBgRGB is null) ||
                            (id.fBgRGB !is null && id.fBgRGB.opEquals(fBgRGB)))
                        return true;
                    // if the only thing that isn't the same is the background color
                    // still return true if it does not matter (percents add up to 100)
                    int sum = 0;
                    for (int i = 0; i < fPercents.length; i++)
                        sum += fPercents[i];
                    if (sum >= 100)
                        return true;
                }
            }
            return false;
        }

        public override hash_t toHash() {
            int hash = super.toHash();
            hash = hash * 7 + (new Boolean(fVertical)).toHash();
            for (int i = 0; i < fPercents.length; i++)
                hash = hash * 7 + (new Integer(fPercents[i])).toHash();
            return hash;
        }
    }

    private class ImageReference {
        private Image fImage;
        private int fCount;

        public this(Image image) {
            fImage = image;
            fCount = 1;
        }

        public Image getImage() {
            return fImage;
        }
        // returns a bool indicating if all clients of this image are finished
        // a true result indicates the underlying image should be disposed
        public bool decCount() {
            return --fCount is 0;
        }
        public void incCount() {
            fCount++;
        }
    }

    public Image getGradient(Display display, Color color1, Color color2,
            int realtheight, int theight, int marginHeight) {
        checkHashMaps();
        ImageIdentifier id = new SimpleImageIdentifier(display, color1, color2, realtheight, theight, marginHeight);
        ImageReference result = cast(ImageReference) images.get(id);
        if (result !is null && !result.getImage().isDisposed()) {
            result.incCount();
            return result.getImage();
        }
        Image image = createGradient(display, color1, color2, realtheight, theight, marginHeight);
        images.put(id, new ImageReference(image));
        ids.put(image, id);
        return image;
    }

    public Image getGradient(Display display, Color[] colors, int[] percents,
            int length, bool vertical, Color bg) {
        checkHashMaps();
        ImageIdentifier id = new ComplexImageIdentifier(display, colors, length, percents, vertical, bg);
        ImageReference result = cast(ImageReference) images.get(id);
        if (result !is null && !result.getImage().isDisposed()) {
            result.incCount();
            return result.getImage();
        }
        Image image = createGradient(display, colors, percents, length, vertical, bg);
        images.put(id, new ImageReference(image));
        ids.put(image, id);
        return image;
    }

    public bool markFinished(Image image) {
        checkHashMaps();
        ImageIdentifier id = cast(ImageIdentifier)ids.get(image);
        if (id !is null) {
            ImageReference ref_ = cast(ImageReference) images.get(id);
            if (ref_ !is null) {
                if (ref_.decCount()) {
                    images.remove(id);
                    ids.remove(ref_.getImage());
                    ref_.getImage().dispose();
                    validateHashMaps();
                }
                return true;
            }
        }
        // if the image was not found, dispose of it for the caller
        image.dispose();
        return false;
    }

    private void checkHashMaps() {
        if (images is null)
            images = new HashMap();
        if (ids is null)
            ids = new HashMap();
    }

    private void validateHashMaps() {
        if (images.size() is 0)
            images = null;
        if (ids.size() is 0)
            ids = null;
    }

    private Image createGradient(Display display, Color color1, Color color2,
            int realtheight, int theight, int marginHeight) {
        Image image = new Image(display, 1, realtheight);
        image.setBackground(color1);
        GC gc = new GC(image);
        gc.setBackground(color1);
        gc.fillRectangle(0, 0, 1, realtheight);
        gc.setForeground(color2);
        gc.setBackground(color1);
        gc.fillGradientRectangle(0, marginHeight + 2, 1, theight - 2, true);
        gc.dispose();
        return image;
    }

    private Image createGradient(Display display, Color[] colors, int[] percents,
            int length, bool vertical, Color bg) {
        int width = vertical ? 1 : length;
        int height = vertical ? length : 1;
        Image gradient = new Image(display, Math.max(width, 1), Math
                .max(height, 1));
        GC gc = new GC(gradient);
        drawTextGradient(gc, width, height, colors, percents, vertical, bg);
        gc.dispose();
        return gradient;
    }

    private void drawTextGradient(GC gc, int width, int height, Color[] colors,
            int[] percents, bool vertical, Color bg) {
        final Color oldBackground = gc.getBackground();
        if (colors.length is 1) {
            if (colors[0] !is null)
                gc.setBackground(colors[0]);
            gc.fillRectangle(0, 0, width, height);
        } else {
            final Color oldForeground = gc.getForeground();
            Color lastColor = colors[0];
            if (lastColor is null)
                lastColor = oldBackground;
            int pos = 0;
            for (int i = 0; i < percents.length; ++i) {
                gc.setForeground(lastColor);
                lastColor = colors[i + 1];
                if (lastColor is null)
                    lastColor = oldBackground;
                gc.setBackground(lastColor);
                if (vertical) {
                    int gradientHeight = percents[i] * height / 100;

                    gc.fillGradientRectangle(0, pos, width, gradientHeight,
                            true);
                    pos += gradientHeight;
                } else {
                    int gradientWidth = percents[i] * height / 100;

                    gc.fillGradientRectangle(pos, 0, gradientWidth, height,
                            false);
                    pos += gradientWidth;
                }
            }
            if (vertical && pos < height) {
                if (bg !is null)
                    gc.setBackground(bg);
                gc.fillRectangle(0, pos, width, height - pos);
            }
            if (!vertical && pos < width) {
                if (bg !is null)
                    gc.setBackground(bg);
                gc.fillRectangle(pos, 0, width - pos, height);
            }
            gc.setForeground(oldForeground);
        }
    }
}
