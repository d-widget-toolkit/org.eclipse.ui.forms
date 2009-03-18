/*******************************************************************************
 * Copyright (c) 2006, 2007 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Stefan Mucke - fix for Bug 156456
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/
module org.eclipse.ui.internal.forms.widgets.BusyIndicator;

import org.eclipse.ui.internal.forms.widgets.FormUtil;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Display;
// import org.eclipse.core.runtime.FileLocator;
// import org.eclipse.core.runtime.Path;
// import org.eclipse.core.runtime.Platform;
import org.eclipse.jface.resource.ImageDescriptor;

import java.lang.all;
import java.util.Set;

import tango.util.Convert;
import java.lang.Thread;

public final class BusyIndicator : Canvas {

    alias Canvas.computeSize computeSize;

    class BusyThread : Thread {
        Rectangle bounds;
        Display display;
        GC offScreenImageGC;
        Image offScreenImage;
        Image timage;
        bool stop;

        private this(Rectangle bounds, Display display, GC offScreenImageGC, Image offScreenImage) {
            this.bounds = bounds;
            this.display = display;
            this.offScreenImageGC = offScreenImageGC;
            this.offScreenImage = offScreenImage;
        }

        public override void run() {
            try {
                /*
                 * Create an off-screen image to draw on, and fill it with
                 * the shell background.
                 */
                FormUtil.setAntialias(offScreenImageGC, SWT.ON);
                display.syncExec(dgRunnable( {
                        if (!isDisposed())
                            drawBackground(offScreenImageGC, 0, 0,
                                    bounds.width,
                                    bounds.height);
                }));
                if (isDisposed())
                    return;

                /*
                 * Create the first image and draw it on the off-screen
                 * image.
                 */
                int imageDataIndex = 0;
                ImageData imageData;
                synchronized (this.outer) {
                    timage = getImage(imageDataIndex);
                    imageData = timage.getImageData();
                    offScreenImageGC.drawImage(timage, 0, 0,
                            imageData.width, imageData.height, imageData.x,
                            imageData.y, imageData.width, imageData.height);
                }

                /*
                 * Now loop through the images, creating and drawing
                 * each one on the off-screen image before drawing it on
                 * the shell.
                 */
                while (!stop && !isDisposed() && timage !is null) {

                    /*
                     * Fill with the background color before
                     * drawing.
                     */
                    display.syncExec(dgRunnable( (ImageData fimageData){
                        if (!isDisposed()) {
                            drawBackground(offScreenImageGC, fimageData.x,
                                    fimageData.y, fimageData.width,
                                    fimageData.height);
                        }
                    }, imageData ));

                    synchronized (this.outer) {
                        imageDataIndex = (imageDataIndex + 1) % IMAGE_COUNT;
                        timage = getImage(imageDataIndex);
                        imageData = timage.getImageData();
                        offScreenImageGC.drawImage(timage, 0, 0,
                                imageData.width, imageData.height,
                                imageData.x, imageData.y, imageData.width,
                                imageData.height);
                    }

                    /* Draw the off-screen image to the shell. */
                    animationImage = offScreenImage;
                    display.syncExec(dgRunnable( {
                        if (!isDisposed())
                            redraw();
                    }));
                    /*
                     * Sleep for the specified delay time
                     */
                    try {
                        Thread.sleep(MILLISECONDS_OF_DELAY);
                    } catch (InterruptedException e) {
                        ExceptionPrintStackTrace(e);
                    }


                }
            } catch (Exception e) {
            } finally {
                display.syncExec(dgRunnable( {
                    if (offScreenImage !is null
                            && !offScreenImage.isDisposed())
                        offScreenImage.dispose();
                    if (offScreenImageGC !is null
                            && !offScreenImageGC.isDisposed())
                        offScreenImageGC.dispose();
                }));
                clearImages();
            }
            if (busyThread is null)
                display.syncExec(dgRunnable( {
                    animationImage = null;
                    if (!isDisposed())
                        redraw();
                }));
        }

        public void setStop(bool stop) {
            this.stop = stop;
        }
    }

    private static const int MARGIN = 0;
    private static const int IMAGE_COUNT = 8;
    private static const int MILLISECONDS_OF_DELAY = 180;
    private Image[] imageCache;
    protected Image image;

    protected Image animationImage;

    protected BusyThread busyThread;

    /**
     * BusyWidget constructor comment.
     *
     * @param parent
     *            org.eclipse.swt.widgets.Composite
     * @param style
     *            int
     */
    public this(Composite parent, int style) {
        super(parent, style);

        addPaintListener(new class PaintListener {
            public void paintControl(PaintEvent event) {
                onPaint(event);
            }
        });
    }

    public Point computeSize(int wHint, int hHint, bool changed) {
        Point size = new Point(0, 0);
        if (image !is null) {
            Rectangle ibounds = image.getBounds();
            size.x = ibounds.width;
            size.y = ibounds.height;
        }
        if (isBusy()) {
            Rectangle bounds = getImage(0).getBounds();
            size.x = Math.max(size.x, bounds.width);
            size.y = Math.max(size.y, bounds.height);
        }
        size.x += MARGIN + MARGIN;
        size.y += MARGIN + MARGIN;
        return size;
    }

    /* (non-Javadoc)
     * @see org.eclipse.swt.widgets.Control#forceFocus()
     */
    public bool forceFocus() {
        return false;
    }

    /**
     * Creates a thread to animate the image.
     */
    protected synchronized void createBusyThread() {
        if (busyThread !is null)
            return;

        Rectangle bounds = getImage(0).getBounds();
        Display display = getDisplay();
        Image offScreenImage = new Image(display, bounds.width, bounds.height);
        GC offScreenImageGC = new GC(offScreenImage);
        busyThread = new BusyThread(bounds, display, offScreenImageGC, offScreenImage);
        busyThread.setPriority(Thread.NORM_PRIORITY + 2);
        busyThread.setDaemon(true);
        busyThread.start();
    }

    public void dispose() {
        if (busyThread !is null) {
            busyThread.setStop(true);
            busyThread = null;
        }
        super.dispose();
    }

    /**
     * Return the image or <code>null</code>.
     */
    public Image getImage() {
        return image;
    }

    /**
     * Returns true if it is currently busy.
     *
     * @return bool
     */
    public bool isBusy() {
        return (busyThread !is null);
    }

    /*
     * Process the paint event
     */
    protected void onPaint(PaintEvent event) {
        if (animationImage !is null && animationImage.isDisposed()) {
            animationImage = null;
        }
        Rectangle rect = getClientArea();
        if (rect.width is 0 || rect.height is 0)
            return;

        GC gc = event.gc;
        Image activeImage = animationImage !is null ? animationImage : image;
        if (activeImage !is null) {
            Rectangle ibounds = activeImage.getBounds();
            gc.drawImage(activeImage, rect.width / 2 - ibounds.width / 2,
                    rect.height / 2 - ibounds.height / 2);
        }
    }

    /**
     * Sets the indicators busy count up (true) or down (false) one.
     *
     * @param busy
     *            bool
     */
    public synchronized void setBusy(bool busy) {
        if (busy) {
            if (busyThread is null)
                createBusyThread();
        } else {
            if (busyThread !is null) {
                busyThread.setStop(true);
                busyThread = null;
            }
        }
    }

    /**
     * Set the image. The value <code>null</code> clears it.
     */
    public void setImage(Image image) {
        if (image !is this.image && !isDisposed()) {
            this.image = image;
            redraw();
        }
    }


    private ImageDescriptor createImageDescriptor(String relativePath) {
//         Bundle bundle = Platform.getBundle("org.eclipse.ui.forms"); //$NON-NLS-1$
//         URL url = FileLocator.find(bundle, new Path(relativePath),null);
//         if (url is null) return null;
//         try {
//             url = FileLocator.resolve(url);
//             return ImageDescriptor.createFromURL(url);
//         } catch (IOException e) {
//             return null;
//         }
        return null;
    }

    private synchronized Image getImage(int index) {
        if (imageCache is null) {
            imageCache = new Image[IMAGE_COUNT];
        }
        if (imageCache[index] is null){
            ImageDescriptor descriptor = createImageDescriptor("$nl$/icons/progress/ani/" ~ to!(String)(index + 1) ~ ".png"); //$NON-NLS-1$ //$NON-NLS-2$
            imageCache[index] = descriptor.createImage();
        }
        return imageCache[index];
    }

    private synchronized void clearImages() {
        if (busyThread !is null)
            return;
        if (imageCache !is null) {
            for (int index = 0; index < IMAGE_COUNT; index++) {
                if (imageCache[index] !is null && !imageCache[index].isDisposed()) {
                    imageCache[index].dispose();
                    imageCache[index] = null;
                }
            }
        }
    }

}
