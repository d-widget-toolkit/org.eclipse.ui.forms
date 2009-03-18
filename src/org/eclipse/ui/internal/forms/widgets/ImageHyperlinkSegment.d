/*******************************************************************************
 * Copyright (c) 2003, 2005 IBM Corporation and others.
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
module org.eclipse.ui.internal.forms.widgets.ImageHyperlinkSegment;

import org.eclipse.ui.internal.forms.widgets.IHyperlinkSegment;
import org.eclipse.ui.internal.forms.widgets.ImageSegment;

//import java.util.Hashtable;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Rectangle;

import java.lang.all;
import java.util.Hashtable;
import java.util.Set;

public class ImageHyperlinkSegment : ImageSegment,
        IHyperlinkSegment {
    private String href;
    private String text;

    private String tooltipText;

    // reimpl for interface
    bool contains(int x, int y){
        return super.contains(x,y);
    }
    bool intersects(Rectangle rect){
        return super.intersects(rect);
    }

    public this() {
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.internal.forms.widgets.IHyperlinkSegment#setHref(java.lang.String)
     */
    public void setHref(String href) {
        this.href = href;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.internal.forms.widgets.IHyperlinkSegment#getHref()
     */
    public String getHref() {
        return href;
    }

    public void paintFocus(GC gc, Color bg, Color fg, bool selected,
            Rectangle repaintRegion) {
        Rectangle bounds = getBounds();
        if (bounds is null)
            return;
        if (selected) {
            gc.setBackground(bg);
            gc.setForeground(fg);
            gc.drawFocus(bounds.x, bounds.y, bounds.width, bounds.height);
        } else {
            gc.setForeground(bg);
            gc.drawRectangle(bounds.x, bounds.y, bounds.width - 1,
                    bounds.height - 1);
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.internal.forms.widgets.IHyperlinkSegment#isWordWrapAllowed()
     */
    public bool isWordWrapAllowed() {
        return !isNowrap();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.internal.forms.widgets.IHyperlinkSegment#setWordWrapAllowed(bool)
     */
    public void setWordWrapAllowed(bool value) {
        setNowrap(!value);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.internal.forms.widgets.IHyperlinkSegment#getText()
     */
    public String getText() {
        return text !is null?text:""; //$NON-NLS-1$
    }

    public void setText(String text) {
        this.text = text;
    }

    /**
     * @return Returns the tooltipText.
     */
    public String getTooltipText() {
        return tooltipText;
    }

    /**
     * @param tooltipText
     *            The tooltipText to set.
     */
    public void setTooltipText(String tooltipText) {
        this.tooltipText = tooltipText;
    }

    public bool isSelectable() {
        return true;
    }

    public bool isFocusSelectable(Hashtable resourceTable) {
        return true;
    }

    public bool setFocus(Hashtable resourceTable, bool direction) {
        return true;
    }
}
