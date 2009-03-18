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
module org.eclipse.ui.internal.forms.widgets.Paragraph;

import org.eclipse.ui.internal.forms.widgets.ParagraphSegment;
import org.eclipse.ui.internal.forms.widgets.Locator;
import org.eclipse.ui.internal.forms.widgets.IHyperlinkSegment;
import org.eclipse.ui.internal.forms.widgets.SelectionData;
import org.eclipse.ui.internal.forms.widgets.TextSegment;
import org.eclipse.ui.internal.forms.widgets.TextHyperlinkSegment;

import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.ui.forms.HyperlinkSettings;

import java.lang.all;
import java.util.Vector;
import java.util.Hashtable;
import java.util.ArrayList;
import java.util.Set;
import tango.io.model.IFile;

import tango.text.Text;

/**
 * @version 1.0
 * @author
 */
public class Paragraph {
    public static const String HTTP = "http://"; //$NON-NLS-1$

    private Vector segments;

    private bool addVerticalSpace = true;

    public this(bool addVerticalSpace) {
        this.addVerticalSpace = addVerticalSpace;
    }

    public int getIndent() {
        return 0;
    }

    public bool getAddVerticalSpace() {
        return addVerticalSpace;
    }

    /*
     * @see IParagraph#getSegments()
     */
    public ParagraphSegment[] getSegments() {
        if (segments is null)
            return null;
        return arraycast!(ParagraphSegment)(segments
                .toArray());
    }

    public void addSegment(ParagraphSegment segment) {
        if (segments is null)
            segments = new Vector;
        segments.add(segment);
    }

    public void parseRegularText(String text, bool expandURLs, bool wrapAllowed,
            HyperlinkSettings settings, String fontId) {
        parseRegularText(text, expandURLs, wrapAllowed, settings, fontId, null);
    }

    public void parseRegularText(String text, bool expandURLs, bool wrapAllowed,
            HyperlinkSettings settings, String fontId, String colorId) {
        if (text.length is 0)
            return;
        if (expandURLs) {
            int loc = text.indexOf(HTTP);

            if (loc is -1)
                addSegment(new TextSegment(text, fontId, colorId, wrapAllowed));
            else {
                int textLoc = 0;
                while (loc !is -1) {
                    addSegment(new TextSegment(text.substring(textLoc, loc),
                            fontId, colorId, wrapAllowed));
                    bool added = false;
                    for (textLoc = loc; textLoc < text.length; textLoc++) {
                        char c = text.charAt(textLoc);
                        if (CharacterIsWhitespace(c)) {
                            addHyperlinkSegment(text.substring(loc, textLoc),
                                    settings, fontId);
                            added = true;
                            break;
                        }
                    }
                    if (!added) {
                        // there was no space - just end of text
                        addHyperlinkSegment(text.substring(loc), settings,
                                fontId);
                        break;
                    }
                    loc = text.indexOf(HTTP, textLoc);
                }
                if (textLoc < text.length) {
                    addSegment(new TextSegment(text.substring(textLoc), fontId,
                            colorId, wrapAllowed));
                }
            }
        } else {
            addSegment(new TextSegment(text, fontId, colorId, wrapAllowed));
        }
    }

    private void addHyperlinkSegment(String text, HyperlinkSettings settings,
            String fontId) {
        TextHyperlinkSegment hs = new TextHyperlinkSegment(text, settings,
                fontId);
        hs.setWordWrapAllowed(false);
        hs.setHref(text);
        addSegment(hs);
    }

    protected void computeRowHeights(GC gc, int width, Locator loc,
            int lineHeight, Hashtable resourceTable) {
        ParagraphSegment[] segments = getSegments();
        // compute heights
        Locator hloc = loc.create();
        ArrayList heights = new ArrayList();
        hloc.heights = heights;
        hloc.rowCounter = 0;
        int innerWidth = width - loc.marginWidth*2;
        for (int j = 0; j < segments.length; j++) {
            ParagraphSegment segment = segments[j];
            segment.advanceLocator(gc, innerWidth, hloc, resourceTable, true);
        }
        hloc.collectHeights();
        loc.heights = heights;
        loc.rowCounter = 0;
    }

    public void layout(GC gc, int width, Locator loc, int lineHeight,
            Hashtable resourceTable, IHyperlinkSegment selectedLink) {
        ParagraphSegment[] segments = getSegments();
        //int height;
        if (segments.length > 0) {
            /*
            if (segments[0] instanceof TextSegment
                    && ((TextSegment) segments[0]).isSelectable())
                loc.x += 1;
            */
            // compute heights
            if (loc.heights is null)
                computeRowHeights(gc, width, loc, lineHeight, resourceTable);
            for (int j = 0; j < segments.length; j++) {
                ParagraphSegment segment = segments[j];
                bool doSelect = false;
                if (selectedLink !is null && segment.opEquals(cast(Object)selectedLink))
                    doSelect = true;
                segment.layout(gc, width, loc, resourceTable, doSelect);
            }
            loc.heights = null;
            loc.y += loc.rowHeight;
        } else {
            loc.y += lineHeight;
        }
    }

    public void paint(GC gc, Rectangle repaintRegion,
            Hashtable resourceTable, IHyperlinkSegment selectedLink,
            SelectionData selData) {
        ParagraphSegment[] segments = getSegments();

        for (int i = 0; i < segments.length; i++) {
            ParagraphSegment segment = segments[i];
            if (!segment.intersects(repaintRegion))
                continue;
            bool doSelect = false;
            if (selectedLink !is null && segment.opEquals(cast(Object)selectedLink))
                doSelect = true;
            segment.paint(gc, false, resourceTable, doSelect, selData, repaintRegion);
        }
    }

    public void computeSelection(GC gc, Hashtable resourceTable, IHyperlinkSegment selectedLink,
            SelectionData selData) {
        ParagraphSegment[] segments = getSegments();

        for (int i = 0; i < segments.length; i++) {
            ParagraphSegment segment = segments[i];
            //bool doSelect = false;
            //if (selectedLink !is null && segment.equals(selectedLink))
                //doSelect = true;
            segment.computeSelection(gc, resourceTable, selData);
        }
    }

    public String getAccessibleText() {
        ParagraphSegment[] segments = getSegments();
        auto txt = new tango.text.Text.Text!(char);
        for (int i = 0; i < segments.length; i++) {
            ParagraphSegment segment = segments[i];
            if ( auto ts = cast(TextSegment)segment ) {
                String text = ts.getText();
                txt.append(text);
            }
        }
        txt.append( FileConst.NewlineString );
        return txt.toString();
    }

    public ParagraphSegment findSegmentAt(int x, int y) {
        if (segments !is null) {
            for (int i = 0; i < segments.size(); i++) {
                ParagraphSegment segment = cast(ParagraphSegment) segments.get(i);
                if (segment.contains(x, y))
                    return segment;
            }
        }
        return null;
    }
    public void clearCache(String fontId) {
        if (segments !is null) {
            for (int i = 0; i < segments.size(); i++) {
                ParagraphSegment segment = cast(ParagraphSegment) segments.get(i);
                segment.clearCache(fontId);
            }
        }
    }
}
