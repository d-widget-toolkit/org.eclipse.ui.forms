/*******************************************************************************
 * Copyright (c) 2000, 2005 IBM Corporation and others.
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
module org.eclipse.ui.internal.forms.widgets.BreakSegment;

import org.eclipse.ui.internal.forms.widgets.ParagraphSegment;
import org.eclipse.ui.internal.forms.widgets.Locator;
import org.eclipse.ui.internal.forms.widgets.SelectionData;

import org.eclipse.swt.graphics.FontMetrics;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Rectangle;

import java.lang.all;
import java.util.Hashtable;
import java.util.Set;

/**
 * This segment serves as break within a paragraph. It has no data -
 * just starts a new line and resets the locator.
 */

public class BreakSegment : ParagraphSegment {
    /* (non-Javadoc)
     * @see org.eclipse.ui.forms.internal.widgets.ParagraphSegment#advanceLocator(org.eclipse.swt.graphics.GC, int, org.eclipse.ui.forms.internal.widgets.Locator, java.util.Hashtable)
     */
    public bool advanceLocator(GC gc, int wHint, Locator locator,
            Hashtable objectTable, bool computeHeightOnly) {
        if (locator.rowHeight is 0) {
            FontMetrics fm = gc.getFontMetrics();
            locator.rowHeight = fm.getHeight();
        }
        if (computeHeightOnly) locator.collectHeights();
        locator.x = locator.indent;
        locator.y += locator.rowHeight;
        locator.rowHeight = 0;
        locator.leading = 0;
        return true;
    }

    public void paint(GC gc, bool hover, Hashtable resourceTable, bool selected, SelectionData selData, Rectangle repaintRegion) {
        //nothing to paint
    }
    public bool contains(int x, int y) {
        return false;
    }
    public bool intersects(Rectangle rect) {
        return false;
    }
    /* (non-Javadoc)
     * @see org.eclipse.ui.internal.forms.widgets.ParagraphSegment#layout(org.eclipse.swt.graphics.GC, int, org.eclipse.ui.internal.forms.widgets.Locator, java.util.Hashtable, bool, org.eclipse.ui.internal.forms.widgets.SelectionData)
     */
    public void layout(GC gc, int width, Locator locator, Hashtable ResourceTable,
            bool selected) {
        locator.resetCaret();
        if (locator.rowHeight is 0) {
            FontMetrics fm = gc.getFontMetrics();
            locator.rowHeight = fm.getHeight();
        }
        locator.y += locator.rowHeight;
        locator.rowHeight = 0;
        locator.rowCounter++;
    }

    /* (non-Javadoc)
     * @see org.eclipse.ui.internal.forms.widgets.ParagraphSegment#computeSelection(org.eclipse.swt.graphics.GC, java.util.Hashtable, bool, org.eclipse.ui.internal.forms.widgets.SelectionData)
     */
    public void computeSelection(GC gc, Hashtable resourceTable, SelectionData selData) {
        selData.markNewLine();
    }
}
