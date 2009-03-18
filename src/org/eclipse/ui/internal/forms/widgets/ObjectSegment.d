/*******************************************************************************
 * Copyright (c) 2000, 2007 IBM Corporation and others.
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
module org.eclipse.ui.internal.forms.widgets.ObjectSegment;

import org.eclipse.ui.internal.forms.widgets.ParagraphSegment;
import org.eclipse.ui.internal.forms.widgets.Locator;
import org.eclipse.ui.internal.forms.widgets.SelectionData;

import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;

import java.lang.all;
import java.util.Hashtable;
import java.util.Set;

public abstract class ObjectSegment : ParagraphSegment {
    public static const int TOP = 1;

    public static const int MIDDLE = 2;

    public static const int BOTTOM = 3;

    private int alignment = BOTTOM;
    private bool nowrap=false;
    private Rectangle bounds;
    private String objectId;

    public int getVerticalAlignment() {
        return alignment;
    }

    void setVerticalAlignment(int alignment) {
        this.alignment = alignment;
    }

    public String getObjectId() {
        return objectId;
    }

    void setObjectId(String objectId) {
        this.objectId = objectId;
    }

    protected abstract Point getObjectSize(Hashtable resourceTable, int wHint);

    public bool advanceLocator(GC gc, int wHint, Locator loc,
            Hashtable objectTable, bool computeHeightOnly) {
        Point objectSize = getObjectSize(objectTable, wHint);
        int iwidth = 0;
        int iheight = 0;
        bool newLine = false;

        if (objectSize !is null) {
            iwidth = objectSize.x + (isSelectable()?2:0);
            iheight = objectSize.y + (isSelectable()?2:0);
        }
        if (wHint !is SWT.DEFAULT && !nowrap && loc.x + iwidth > wHint) {
            // new line
            if (computeHeightOnly)
                loc.collectHeights();
            loc.x = loc.indent;
            loc.x += iwidth;
            loc.y += loc.rowHeight;
            loc.width = loc.indent + iwidth;
            loc.rowHeight = iheight;
            loc.leading = 0;
            newLine = true;
        } else {
            loc.x += iwidth;
            loc.width += iwidth;
            loc.rowHeight = Math.max(loc.rowHeight, iheight);
        }
        return newLine;
    }

    public bool contains(int x, int y) {
        if (bounds is null)
            return false;
        return bounds.contains(x, y);
    }
    public bool intersects(Rectangle rect) {
        if (bounds is null)
            return false;
        return bounds.intersects(rect);
    }

    public Rectangle getBounds() {
        return bounds;
    }

    public bool isSelectable() {
        return false;
    }
    /**
     * @return Returns the nowrap.
     */
    public bool isNowrap() {
        return nowrap;
    }
    /**
     * @param nowrap The nowrap to set.
     */
    public void setNowrap(bool nowrap) {
        this.nowrap = nowrap;
    }
    public void paint(GC gc, bool hover, Hashtable resourceTable, bool selected, SelectionData selData, Rectangle repaintRegion) {
    }

    /* (non-Javadoc)
     * @see org.eclipse.ui.internal.forms.widgets.ParagraphSegment#layout(org.eclipse.swt.graphics.GC, int, org.eclipse.ui.internal.forms.widgets.Locator, java.util.Hashtable, bool, org.eclipse.ui.internal.forms.widgets.SelectionData)
     */
    public void layout(GC gc, int width, Locator loc, Hashtable resourceTable,
            bool selected) {
        Point size = getObjectSize(resourceTable, width);

        int objWidth = 0;
        int objHeight = 0;
        if (size !is null) {
            objWidth = size.x + (isSelectable()?2:0);
            objHeight = size.y + (isSelectable()?2:0);
        } else
            return;
        loc.width = objWidth;

        if (!nowrap && loc.x + objWidth > width) {
            // new row
            loc.newLine();
            loc.rowCounter++;
        }
        int ix = loc.x;
        int iy = loc.y;

        if (alignment is MIDDLE)
            iy = loc.getMiddle(objHeight, false);
        else if (alignment is BOTTOM)
            iy = loc.getBaseline(objHeight, false);
        loc.x += objWidth;
        loc.rowHeight = Math.max(loc.rowHeight, objHeight);
        bounds = new Rectangle(ix, iy, objWidth, objHeight);
    }
    /* (non-Javadoc)
     * @see org.eclipse.ui.internal.forms.widgets.ParagraphSegment#computeSelection(org.eclipse.swt.graphics.GC, java.util.Hashtable, bool, org.eclipse.ui.internal.forms.widgets.SelectionData)
     */
    public void computeSelection(GC gc, Hashtable resourceTable, SelectionData selData) {
        // TODO we should add this to the selection
        // if we want to support rich text
    }
}
