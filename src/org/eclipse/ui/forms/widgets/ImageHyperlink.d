/*******************************************************************************
 * Copyright (c) 2000, 2007 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Chriss Gross (schtoo@schtoo.com) - fix for 61670
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/
module org.eclipse.ui.forms.widgets.ImageHyperlink;

import org.eclipse.ui.forms.widgets.Hyperlink;

import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Event;

import java.lang.all;
import java.util.Set;

/**
 * This class extends hyperlink widget by adding the capability to render an
 * image relative to the text. If no text has been set, only image will be
 * shown. Images for hover and active states can be set in addition to the
 * normal state image.
 * <p>
 * When image is taller than the text, additional style can be provided to
 * control vertical alignment (supported values are SWT.TOP, SWT.BOTTOM and
 * SWT.CENTER).
 * <p>
 * The class does not need to be sublassed but it is allowed to do so if some
 * aspect of the image hyperlink needs to be modified.
 *
 * @since 3.0
 */
public class ImageHyperlink : Hyperlink {
    /**
     * Amount of pixels between the image and the text (default is 5).
     */
    public int textSpacing = 5;

    private Image image;

    private Image hoverImage;

    private Image activeImage;

    private int state;

    private static const int HOVER = 1 << 1;

    private static const int ACTIVE = 1 << 2;

    private int verticalAlignment = SWT.CENTER;

    private int horizontalAlignment = SWT.LEFT;

    /**
     * Creates the image hyperlink instance.
     *
     * @param parent
     *            the control parent
     * @param style
     *            the control style (SWT.WRAP, BOTTOM, TOP, MIDDLE, LEFT, RIGHT)
     */
    public this(Composite parent, int style) {
        super(parent, removeAlignment(style));
        extractAlignment(style);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.widgets.AbstractHyperlink#paintHyperlink(org.eclipse.swt.events.PaintEvent)
     */
    protected void paintHyperlink(GC gc) {
        paintHyperlink(gc, getClientArea());
    }

    protected void paintHyperlink(GC gc, Rectangle bounds) {
        Image image = null;
        if ((state & ACTIVE) !is 0)
            image = activeImage;
        else if ((state & HOVER) !is 0)
            image = hoverImage;
        if (image is null)
            image = this.image;
        Rectangle ibounds = image !is null ? image.getBounds() : new Rectangle(0, 0, 0, 0);
        Point maxsize = computeMaxImageSize();
        int spacing = image !is null?textSpacing:0;
        int textWidth = bounds.width - maxsize.x - spacing
                - marginWidth - marginWidth;
        int y = bounds.y+marginHeight + maxsize.y / 2 - ibounds.height / 2;

        if (horizontalAlignment is SWT.LEFT) {
            int x = bounds.x+marginWidth + maxsize.x / 2 - ibounds.width / 2;
            int textX = bounds.x + marginWidth + maxsize.x + spacing;
            if (image !is null)
                gc.drawImage(image, x, y);
            if (getText() !is null)
                drawText(gc, bounds, textX, textWidth);
        } else if (horizontalAlignment is SWT.RIGHT) {
            int x = bounds.x+marginWidth;
            if (getText() !is null) {
                x += drawText(gc, bounds, x, textWidth);
            }
            x += maxsize.x / 2 - ibounds.width / 2 + spacing;
            if (image !is null)
                gc.drawImage(image, x, y);
        }
    }

    private int drawText(GC gc, Rectangle clientArea, int textX, int textWidth) {
        Point textSize = computeTextSize(textWidth, SWT.DEFAULT);
        int slotHeight = clientArea.height - marginHeight - marginHeight;
        int textY;
        textWidth = textSize.x;
        int textHeight = textSize.y;
        if (verticalAlignment is SWT.BOTTOM) {
            textY = marginHeight + slotHeight - textHeight;
        } else if (verticalAlignment is SWT.CENTER) {
            textY = marginHeight + slotHeight / 2 - textHeight / 2;
        } else {
            textY = marginHeight;
        }
        paintText(gc, new Rectangle(textX, textY, textWidth, textHeight));
        return textWidth;
    }

    /**
     * Computes the control size by reserving space for images in addition to
     * text.
     *
     * @param wHint
     *            width hint
     * @param hHint
     *            height hint
     * @param changed
     *            if <code>true</code>, any cached layout data should be
     *            computed anew
     */
    public Point computeSize(int wHint, int hHint, bool changed) {
        checkWidget();
        Point isize = computeMaxImageSize();
        int spacing = isize.x>0?textSpacing:0;
        Point textSize = null;
        if (getText() !is null) {
            int innerWHint = wHint;
            if (wHint !is SWT.DEFAULT) {
                innerWHint = wHint - 2 * marginWidth - isize.x - spacing;
            }
            textSize = super.computeSize(innerWHint, hHint, changed);
        }
        int width = isize.x;
        int height = isize.y;
        if (textSize !is null) {
            width += spacing;
            width += textSize.x;
            height = Math.max(height, textSize.y);
        }
        width += 2 * marginWidth;
        height += 2 * marginHeight;
        return new Point(width, height);
    }

    protected void handleEnter(Event e) {
        state = HOVER;
        super.handleEnter(e);
    }

    protected void handleExit(Event e) {
        state = 0;
        super.handleExit(e);
    }

    protected void handleActivate(Event e) {
        state &= ACTIVE;
        redraw();
        super.handleActivate(e);
        state &= ~ACTIVE;
        if (!isDisposed())
            redraw();
    }

    /**
     * Returns active image.
     *
     * @return active image or <code>null</code> if not set.
     */
    public Image getActiveImage() {
        return activeImage;
    }

    /**
     * Sets the image to show when link is activated.
     *
     * @param activeImage
     *
     */
    public void setActiveImage(Image activeImage) {
        this.activeImage = activeImage;
    }

    /**
     * Returns the hover image.
     *
     * @return hover image or <code>null</code> if not set.
     */
    public Image getHoverImage() {
        return hoverImage;
    }

    /**
     * Sets the image to show when link is hover state (on mouse over).
     *
     * @param hoverImage
     */
    public void setHoverImage(Image hoverImage) {
        this.hoverImage = hoverImage;
    }

    /**
     * Returns the image to show in the normal state.
     *
     * @return normal image or <code>null</code> if not set.
     */
    public Image getImage() {
        return image;
    }

    /**
     * Sets the image to show when link is in the normal state.
     *
     * @param image
     */
    public void setImage(Image image) {
        this.image = image;
    }

    private Point computeMaxImageSize() {
        int x = 0;
        int y = 0;
        if (image !is null) {
            x = Math.max(image.getBounds().width, x);
            y = Math.max(image.getBounds().height, y);
        }
        if (hoverImage !is null) {
            x = Math.max(hoverImage.getBounds().width, x);
            y = Math.max(hoverImage.getBounds().height, y);
        }
        if (activeImage !is null) {
            x = Math.max(activeImage.getBounds().width, x);
            y = Math.max(activeImage.getBounds().height, y);
        }
        return new Point(x, y);
    }

    private static int removeAlignment(int style) {
        int resultStyle = style;
        if ((style & SWT.CENTER) !is 0) {
            resultStyle &= (~SWT.CENTER);
        }
        if ((style & SWT.TOP) !is 0) {
            resultStyle &= (~SWT.TOP);
        }
        if ((style & SWT.BOTTOM) !is 0) {
            resultStyle &= (~SWT.BOTTOM);
        }
        if ((style & SWT.LEFT) !is 0) {
            resultStyle &= (~SWT.LEFT);
        }
        if ((style & SWT.RIGHT) !is 0) {
            resultStyle &= (~SWT.RIGHT);
        }
        return resultStyle;
    }

    private void extractAlignment(int style) {
        if ((style & SWT.CENTER) !is 0) {
            verticalAlignment = SWT.CENTER;
        } else if ((style & SWT.TOP) !is 0) {
            verticalAlignment = SWT.TOP;
        } else if ((style & SWT.BOTTOM) !is 0) {
            verticalAlignment = SWT.BOTTOM;
        }
        if ((style & SWT.LEFT) !is 0) {
            horizontalAlignment = SWT.LEFT;
        } else if ((style & SWT.RIGHT) !is 0) {
            horizontalAlignment = SWT.RIGHT;
        }
    }
}
