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
module org.eclipse.ui.internal.forms.widgets.Locator;

import java.lang.all;
import java.util.ArrayList;
import java.util.Set;

public class Locator : Cloneable {
    public int indent;
    public int x, y;
    public int width;
    public int leading;
    public int rowHeight;
    public int marginWidth;
    public int marginHeight;
    public int rowCounter;
    public ArrayList heights;

    public Locator clone(){
        auto res = new Locator();
        res.indent = indent;
        res.x = x;
        res.y = y;
        res.width = width;
        res.leading = leading;
        res.rowHeight = rowHeight;
        res.marginWidth = marginWidth;
        res.marginHeight = marginHeight;
        res.rowCounter = rowCounter;
        res.heights = heights;
        return res;
    }

    public void newLine() {
        resetCaret();
        y += rowHeight;
        rowHeight = 0;
    }

    public Locator create() {
//         try {
            return cast(Locator)clone();
//         }
//         catch (CloneNotSupportedException e) {
//             return null;
//         }
    }
    public void collectHeights() {
        heights.add(new ArrayWrapperObject( [ new Integer(rowHeight), new Integer(leading) ] ) );
        rowCounter++;
    }
    public int getBaseline(int segmentHeight) {
        return getBaseline(segmentHeight, true);

    }
    public int getMiddle(int segmentHeight, bool text) {
        if (heights !is null && heights.size() > rowCounter) {
            Integer [] rdata = arrayFromObject!(Integer)(heights.get(rowCounter));
            int rheight = rdata[0].intValue();
            int rleading = rdata[1].intValue();
            if (text)
                return y + rheight/2 - segmentHeight/2 - rleading;
            return y + rheight/2 - segmentHeight/2;
        }
        return y;
    }
    public int getBaseline(int segmentHeight, bool text) {
        if (heights !is null && heights.size()>rowCounter) {
            Integer [] rdata = arrayFromObject!(Integer)(heights.get(rowCounter));
            int rheight = rdata[0].intValue();
            int rleading = rdata[1].intValue();
            if (text)
                return y + rheight - segmentHeight - rleading;
            return y + rheight - segmentHeight;
        }
        return y;
    }

    public void resetCaret() {
        x = getStartX();
    }
    public int getStartX() {
        return marginWidth + indent;
    }
}
