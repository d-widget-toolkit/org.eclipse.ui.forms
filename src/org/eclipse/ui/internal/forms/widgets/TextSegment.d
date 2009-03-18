/*******************************************************************************
 * Copyright (c) 2000, 2008 IBM Corporation and others.
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
module org.eclipse.ui.internal.forms.widgets.TextSegment;

import org.eclipse.ui.internal.forms.widgets.ParagraphSegment;
import org.eclipse.ui.internal.forms.widgets.Locator;
import org.eclipse.ui.internal.forms.widgets.SelectionData;
import org.eclipse.ui.internal.forms.widgets.FormTextModel;

// import com.ibm.icu.text.BreakIterator;

import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.FontMetrics;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;

import java.lang.all;
import java.util.Vector;
import java.util.Hashtable;
import java.util.ArrayList;
import java.util.Set;
import java.mangoicu.UBreakIterator;

/**
 * @version 1.0
 * @author
 */
public class TextSegment : ParagraphSegment {

    private String colorId;

    private String fontId;

    private String text;

    protected bool underline;

    private bool wrapAllowed = true;

    protected Vector areaRectangles;

    private TextFragment[] textFragments;

    class AreaRectangle {
        Rectangle rect;

        int from, to;

        public this(Rectangle rect, int from, int to) {
            this.rect = rect;
            this.from = from;
            this.to = to;
        }

        public bool contains(int x, int y) {
            return rect.contains(x, y);
        }

        public bool intersects(Rectangle region) {
            return rect.intersects(region);
        }

        public String getText() {
            if (from is 0 && to is -1)
                return this.outer.getText();
            if (from > 0 && to is -1)
                return this.outer.getText().substring(from);
            return this.outer.getText().substring(from, to);
        }
    }

    static class SelectionRange {
        public int start;

        public int stop;

        public this() {
            reset();
        }

        public void reset() {
            start = -1;
            stop = -1;
        }
    }

    static class TextFragment {
        short index;

        short length;

        public this(short index, short length) {
            this.index = index;
            this.length = length;
        }
    }

    public this(String text, String fontId) {
        this(text, fontId, null, true);
    }

    public this(String text, String fontId, String colorId) {
        this(text, fontId, colorId, true);
    }

    public this(String text, String fontId, String colorId, bool wrapAllowed) {
        areaRectangles = new Vector();
        this.text = cleanup(text);
        this.fontId = fontId;
        this.colorId = colorId;
        this.wrapAllowed = wrapAllowed;
    }

    private String cleanup(String text) {
        StringBuffer buf = new StringBuffer();
        for (int i = 0; i < text.length; i++) {
            char c = text.charAt(i);
            if (c is '\n' || c is '\r' || c is '\f') {
                if (i > 0)
                    buf.append(' ');
            } else
                buf.append(c);
        }
        return buf.toString();
    }

    public void setWordWrapAllowed(bool value) {
        wrapAllowed = value;
    }

    public bool isWordWrapAllowed() {
        return wrapAllowed;
    }

    public bool isSelectable() {
        return false;
    }

    public String getColorId() {
        return colorId;
    }

    public String getText() {
        return text;
    }

    void setText(String text) {
        this.text = cleanup(text);
        textFragments = null;
    }

    void setColorId(String colorId) {
        this.colorId = colorId;
    }

    void setFontId(String fontId) {
        this.fontId = fontId;
        textFragments = null;
    }

    public bool contains(int x, int y) {
        for (int i = 0; i < areaRectangles.size(); i++) {
            AreaRectangle ar = cast(AreaRectangle) areaRectangles.get(i);
            if (ar.contains(x, y))
                return true;
            if (i<areaRectangles.size()-1) {
                // test the gap
                Rectangle top = ar.rect;
                Rectangle bot = (cast(AreaRectangle)areaRectangles.get(i+1)).rect;
                if (y >= top.y+top.height && y < bot.y) {
                    // in the gap
                    int left = Math.max(top.x, bot.x);
                    int right = Math.min(top.x+top.width, bot.x+bot.width);
                    if (x>=left && x<=right) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    public bool intersects(Rectangle rect) {
        for (int i = 0; i < areaRectangles.size(); i++) {
            AreaRectangle ar = cast(AreaRectangle) areaRectangles.get(i);
            if (ar.intersects(rect))
                return true;
            if (i<areaRectangles.size()-1) {
                // test the gap
                Rectangle top = ar.rect;
                Rectangle bot = (cast(AreaRectangle)areaRectangles.get(i+1)).rect;
                if (top.y+top.height < bot.y) {
                    int y = top.y+top.height;
                    int height = bot.y-y;
                    int left = Math.max(top.x, bot.x);
                    int right = Math.min(top.x+top.width, bot.x+bot.width);
                    Rectangle gap = new Rectangle(left, y, right-left, height);
                    if (gap.intersects(rect))
                        return true;
                }
            }
        }
        return false;
    }

    public Rectangle getBounds() {
        int x = 0, y = 0;
        int width = 0, height = 0;

        for (int i = 0; i < areaRectangles.size(); i++) {
            AreaRectangle ar = cast(AreaRectangle) areaRectangles.get(i);
            if (i is 0) {
                x = ar.rect.x;
                y = ar.rect.y;
            } else
                x = Math.min(ar.rect.x, x);
            width = Math.max(ar.rect.width, width);
            height += ar.rect.height;
        }
        return new Rectangle(x, y, width, height);
    }

    public bool advanceLocator(GC gc, int wHint, Locator locator,
            Hashtable objectTable, bool computeHeightOnly) {
        Font oldFont = null;
        if (fontId !is null) {
            oldFont = gc.getFont();
            Font newFont = cast(Font) objectTable.get(fontId);
            if (newFont !is null)
                gc.setFont(newFont);
        }
        FontMetrics fm = gc.getFontMetrics();
        int lineHeight = fm.getHeight();
        bool newLine = false;

        if (wHint is SWT.DEFAULT || !wrapAllowed) {
            Point extent = gc.textExtent(text);
            int totalExtent = locator.x+extent.x;
            if (isSelectable())
                totalExtent+=1;

            if (wHint !is SWT.DEFAULT && totalExtent > wHint) {
                // new line
                locator.x = locator.indent;
                locator.y += locator.rowHeight;
                if (computeHeightOnly)
                    locator.collectHeights();
                locator.rowHeight = 0;
                locator.leading = 0;
                newLine = true;
            }
            int width = extent.x;
            if (isSelectable())
                width += 1;
            locator.x += width;
            locator.width = locator.indent + width;
            locator.rowHeight = Math.max(locator.rowHeight, extent.y);
            locator.leading = Math.max(locator.leading, fm.getLeading());
            return newLine;
        }

        computeTextFragments(gc);

        int width = 0;
        Point lineExtent = new Point(0, 0);

        for (int i = 0; i < textFragments.length; i++) {
            TextFragment textFragment = textFragments[i];
            int currentExtent = locator.x + lineExtent.x;

            if (isSelectable())
                currentExtent += 1;

            // i !is 0 || locator.x > locator.getStartX() + (isSelectable() ? 1 : 0) means:
            // only wrap on the first fragment if we are not at the start of a line
            if ((i !is 0 || locator.x > locator.getStartX() + (isSelectable() ? 1 : 0)) && currentExtent + textFragment.length > wHint) {
                // overflow
                int lineWidth = currentExtent;
                locator.rowHeight = Math.max(locator.rowHeight, lineExtent.y);
                locator.leading = Math.max(locator.leading, fm.getLeading());
                if (computeHeightOnly)
                    locator.collectHeights();
                locator.x = locator.indent;
                locator.y += locator.rowHeight;
                locator.rowHeight = 0;
                locator.leading = 0;
                lineExtent.x = 0;
                lineExtent.y = 0;
                width = Math.max(width, lineWidth);
                newLine = true;
            }
            lineExtent.x += textFragment.length;
            lineExtent.y = Math.max(lineHeight, lineExtent.y);
        }
        int lineWidth = lineExtent.x;
        if (isSelectable())
            lineWidth += 1;
        locator.x += lineWidth;
        locator.width = width;
        locator.rowHeight = Math.max(locator.rowHeight, lineExtent.y);
        locator.leading = Math.max(locator.leading, fm.getLeading());
        if (oldFont !is null) {
            gc.setFont(oldFont);
        }
        return newLine;
    }

    /**
     * @param gc
     * @param width
     * @param locator
     * @param selected
     * @param selData
     * @param color
     * @param fm
     * @param lineHeight
     * @param descent
     */
    private void layoutWithoutWrapping(GC gc, int width, Locator locator,
            bool selected, FontMetrics fm, int lineHeight, int descent) {
        Point extent = gc.textExtent(text);
        int ewidth = extent.x;
        if (isSelectable())
            ewidth += 1;
        if (locator.x + ewidth > width-locator.marginWidth) {
            // new line
            locator.resetCaret();
            locator.y += locator.rowHeight;
            locator.rowHeight = 0;
            locator.rowCounter++;
        }
        int ly = locator.getBaseline(fm.getHeight() - fm.getLeading());
        //int lineY = ly + lineHeight - descent + 1;
        Rectangle br = new Rectangle(locator.x, ly, ewidth,
                lineHeight - descent + 3);
        areaRectangles.add(new AreaRectangle(br, 0, -1));
        locator.x += ewidth;
        locator.width = ewidth;
        locator.rowHeight = Math.max(locator.rowHeight, extent.y);
    }

    protected int convertOffsetToStringIndex(GC gc, String s, int x,
            int swidth, int selOffset) {
        int index = s.length;
        while (index > 0 && x + swidth > selOffset) {
            index--;
            String ss = s.substring(0, index);
            swidth = gc.textExtent(ss).x;
        }
        return index;
    }

    public void paintFocus(GC gc, Color bg, Color fg, bool selected,
            Rectangle repaintRegion) {
        if (areaRectangles is null)
            return;
        for (int i = 0; i < areaRectangles.size(); i++) {
            AreaRectangle areaRectangle = cast(AreaRectangle) areaRectangles.get(i);
            Rectangle br = areaRectangle.rect;
            int bx = br.x;
            int by = br.y;
            if (repaintRegion !is null) {
                bx -= repaintRegion.x;
                by -= repaintRegion.y;
            }
            if (selected) {
                gc.setBackground(bg);
                gc.setForeground(fg);
                gc.drawFocus(bx, by, br.width, br.height);
            } else {
                gc.setForeground(bg);
                gc.drawRectangle(bx, by, br.width - 1, br.height - 1);
            }
        }
    }

    public void paint(GC gc, bool hover, Hashtable resourceTable,
            bool selected, SelectionData selData, Rectangle repaintRegion) {
        this.paint(gc, hover, resourceTable, selected, false, selData,
                repaintRegion);
    }

    protected void paint(GC gc, bool hover, Hashtable resourceTable,
            bool selected, bool rollover, SelectionData selData,
            Rectangle repaintRegion) {
        Font oldFont = null;
        Color oldColor = null;
        Color oldBg = null;

        // apply segment-specific font, color and background
        if (fontId !is null) {
            oldFont = gc.getFont();
            Font newFont = cast(Font) resourceTable.get(fontId);
            if (newFont !is null)
                gc.setFont(newFont);
        }
        if (!hover && colorId !is null) {
            oldColor = gc.getForeground();
            Color newColor = cast(Color) resourceTable.get(colorId);
            if (newColor !is null)
                gc.setForeground(newColor);
        }
        oldBg = gc.getBackground();

        FontMetrics fm = gc.getFontMetrics();
        int lineHeight = fm.getHeight();
        int descent = fm.getDescent();

        // paint area rectangles of the segment
        for (int i = 0; i < areaRectangles.size(); i++) {
            AreaRectangle areaRectangle = cast(AreaRectangle) areaRectangles.get(i);
            Rectangle rect = areaRectangle.rect;
            String text = areaRectangle.getText();
            Point extent = gc.textExtent(text);
            int textX = rect.x + (isSelectable()?1:0);
            int lineY = rect.y + lineHeight - descent + 1;
            paintString(gc, text, extent.x, textX, rect.y, lineY, selData,
                    rect, hover, rollover, repaintRegion);
            if (selected) {
                int fx = rect.x;
                int fy = rect.y;
                if (repaintRegion !is null) {
                    fx -= repaintRegion.x;
                    fy -= repaintRegion.y;
                }
                //To avoid partially cancelling the focus by painting over
                //X-ORed pixels, first cancel it yourself
                Color fg = gc.getForeground();
                gc.setForeground(oldBg);
                gc.drawRectangle(fx, fy, rect.width - 1, rect.height - 1);
                gc.setForeground(fg);
                gc.drawFocus(fx, fy, rect.width, rect.height);
            }
        }
        // restore GC resources
        if (oldFont !is null) {
            gc.setFont(oldFont);
        }
        if (oldColor !is null) {
            gc.setForeground(oldColor);
        }
        if (oldBg !is null) {
            gc.setBackground(oldBg);
        }
    }

    public void computeSelection(GC gc, Hashtable resourceTable, SelectionData selData) {
        Font oldFont = null;

        if (fontId !is null) {
            oldFont = gc.getFont();
            Font newFont = cast(Font) resourceTable.get(fontId);
            if (newFont !is null)
                gc.setFont(newFont);
        }

        for (int i = 0; i < areaRectangles.size(); i++) {
            AreaRectangle areaRectangle = cast(AreaRectangle) areaRectangles.get(i);
            Rectangle rect = areaRectangle.rect;
            String text = areaRectangle.getText();
            Point extent = gc.textExtent(text);
            computeSelection(gc, text, extent.x, selData,
                    rect);
        }
        // restore GC resources
        if (oldFont !is null) {
            gc.setFont(oldFont);
        }
    }

    private void paintString(GC gc, String s, int swidth, int x, int y,
            int lineY, SelectionData selData, Rectangle bounds, bool hover,
            bool rolloverMode, Rectangle repaintRegion) {
        // repaints one area rectangle
        if (selData !is null && selData.isEnclosed()) {
            Color savedBg = gc.getBackground();
            Color savedFg = gc.getForeground();
            int leftOffset = selData.getLeftOffset(bounds.height);
            int rightOffset = selData.getRightOffset(bounds.height);
            bool firstRow = selData.isFirstSelectionRow(bounds.y,
                    bounds.height);
            bool lastRow = selData.isLastSelectionRow(bounds.y,
                    bounds.height);
            bool selectedRow = selData
                    .isSelectedRow(bounds.y, bounds.height);

            int sstart = -1;
            int sstop = -1;

            if ((firstRow && x + swidth < leftOffset)
                    || (lastRow && x > rightOffset)) {
                paintStringSegment(gc, s, gc.textExtent(s).x, x, y, lineY,
                        hover, rolloverMode, repaintRegion);
                return;
            }

            if (firstRow && bounds.x + swidth > leftOffset) {
                sstart = convertOffsetToStringIndex(gc, s, bounds.x, swidth,
                        leftOffset);
            }
            if (lastRow && bounds.x + swidth > rightOffset) {
                sstop = convertOffsetToStringIndex(gc, s, bounds.x, swidth,
                        rightOffset);
            }

            if (firstRow && sstart !is -1) {
                String left = s.substring(0, sstart);
                int width = gc.textExtent(left).x;
                paintStringSegment(gc, left, width, x, y, lineY, hover,
                        rolloverMode, repaintRegion);
                x += width;
            }
            if (selectedRow) {
                int lindex = sstart !is -1 ? sstart : 0;
                int rindex = sstop !is -1 ? sstop : s.length;
                String mid = s.substring(lindex, rindex);
                Point extent = gc.textExtent(mid);
                gc.setForeground(selData.fg);
                gc.setBackground(selData.bg);
                gc.fillRectangle(x, y, extent.x, extent.y);
                paintStringSegment(gc, mid, extent.x, x, y, lineY, hover,
                        rolloverMode, repaintRegion);
                x += extent.x;
                gc.setForeground(savedFg);
                gc.setBackground(savedBg);
            } else {
                paintStringSegment(gc, s, gc.textExtent(s).x, x, y, lineY,
                        hover, rolloverMode, repaintRegion);
            }
            if (lastRow && sstop !is -1) {
                String right = s.substring(sstop);
                paintStringSegment(gc, right, gc.textExtent(right).x, x, y,
                        lineY, hover, rolloverMode, repaintRegion);
            }
        } else {
            paintStringSegment(gc, s, gc.textExtent(s).x, x, y, lineY, hover,
                    rolloverMode, repaintRegion);
        }
    }

    private void computeSelection(GC gc, String s, int swidth, SelectionData selData, Rectangle bounds) {
        int leftOffset = selData.getLeftOffset(bounds.height);
        int rightOffset = selData.getRightOffset(bounds.height);
        bool firstRow = selData.isFirstSelectionRow(bounds.y, bounds.height);
        bool lastRow = selData.isLastSelectionRow(bounds.y, bounds.height);
        bool selectedRow = selData.isSelectedRow(bounds.y, bounds.height);

        int sstart = -1;
        int sstop = -1;

        if (firstRow && bounds.x + swidth > leftOffset) {
            sstart = convertOffsetToStringIndex(gc, s, bounds.x, swidth,
                    leftOffset);
        }
        if (lastRow && bounds.x + swidth > rightOffset) {
            sstop = convertOffsetToStringIndex(gc, s, bounds.x, swidth,
                    rightOffset);
        }

        if (selectedRow) {
            int lindex = sstart !is -1 ? sstart : 0;
            int rindex = sstop !is -1 ? sstop : s.length;
            String mid = s.substring(lindex, rindex);
            selData.addSegment(mid);
        }
    }

    /**
     * @param gc
     * @param s
     * @param x
     * @param y
     * @param lineY
     * @param hover
     * @param rolloverMode
     */
    private void paintStringSegment(GC gc, String s, int swidth, int x, int y,
            int lineY, bool hover, bool rolloverMode,
            Rectangle repaintRegion) {
        bool reverse = false;
        int clipX = x;
        int clipY = y;
        int clipLineY = lineY;
        if (repaintRegion !is null) {
            clipX -= repaintRegion.x;
            clipY -= repaintRegion.y;
            clipLineY -= repaintRegion.y;
        }
        if (underline || hover || rolloverMode) {
            if (rolloverMode && !hover)
                reverse = true;
        }
        if (reverse) {
            drawUnderline(gc, swidth, clipX, clipLineY, hover, rolloverMode);
            drawString(gc, s, clipX, clipY);
        } else {
            drawString(gc, s, clipX, clipY);
            drawUnderline(gc, swidth, clipX, clipLineY, hover, rolloverMode);
        }
    }

    protected void drawString(GC gc, String s, int clipX, int clipY) {
        gc.drawString(s, clipX, clipY, true);
    }

    private void drawUnderline(GC gc, int swidth, int x, int y, bool hover,
            bool rolloverMode) {
        if (underline || hover || rolloverMode) {
            Color saved = null;
            if (rolloverMode && !hover) {
                saved = gc.getForeground();
                gc.setForeground(gc.getBackground());
            }
            gc.drawLine(x, y, x + swidth-1, y);
            if (saved !is null)
                gc.setForeground(saved);
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.internal.forms.widgets.ParagraphSegment#layout(org.eclipse.swt.graphics.GC,
     *      int, org.eclipse.ui.internal.forms.widgets.Locator,
     *      java.util.Hashtable, bool,
     *      org.eclipse.ui.internal.forms.widgets.SelectionData)
     */
    public void layout(GC gc, int width, Locator locator,
            Hashtable resourceTable, bool selected) {
        Font oldFont = null;

        areaRectangles.clear();

        if (fontId !is null) {
            oldFont = gc.getFont();
            Font newFont = cast(Font) resourceTable.get(fontId);
            if (newFont !is null)
                gc.setFont(newFont);
        }
        FontMetrics fm = gc.getFontMetrics();
        int lineHeight = fm.getHeight();
        int descent = fm.getDescent();

        if (!wrapAllowed) {
            layoutWithoutWrapping(gc, width, locator, selected, fm, lineHeight,
                    descent);
        } else {
            int lineStart = 0;
            int lastLoc = 0;
            Point lineExtent = new Point(0, 0);
            computeTextFragments(gc);
            int rightEdge = width-locator.marginWidth;
            for (int i = 0; i < textFragments.length; i++) {
                TextFragment fragment = textFragments[i];
                int breakLoc = fragment.index;
                if (breakLoc is 0)
                    continue;
                // (i !is 0 || locator.x > locator.getStartX() + (isSelectable() ? 1 : 0)) means:
                // only wrap on the first fragment if we are not at the start of a line
                if ((i !is 0 || locator.x > locator.getStartX() + (isSelectable() ? 1 : 0)) && locator.x + lineExtent.x + fragment.length > rightEdge) {
                    // overflow
                    int lineWidth = locator.x + lineExtent.x;
                    if (isSelectable())
                        lineWidth += 1;
                    int ly = locator.getBaseline(lineHeight - fm.getLeading());
                    Rectangle br = new Rectangle(isSelectable()?
                            locator.x - 1:locator.x, ly,
                            isSelectable()?lineExtent.x + 1:lineExtent.x, lineHeight - descent + 3);
                    areaRectangles
                            .add(new AreaRectangle(br, lineStart, lastLoc));

                    locator.rowHeight = Math.max(locator.rowHeight,
                            lineExtent.y);
                    locator.resetCaret();
                    if (isSelectable())
                        locator.x += 1;
                    locator.y += locator.rowHeight;
                    locator.rowCounter++;
                    locator.rowHeight = 0;
                    lineStart = lastLoc;
                    lineExtent.x = 0;
                    lineExtent.y = 0;
                }
                lastLoc = breakLoc;
                lineExtent.x += fragment.length;
                lineExtent.y = Math.max(lineHeight, lineExtent.y);
            }
            //String lastLine = text.substring(lineStart, lastLoc);
            int ly = locator.getBaseline(lineHeight - fm.getLeading());
            int lastWidth = lineExtent.x;
            if (isSelectable())
                lastWidth += 1;
            Rectangle br = new Rectangle(isSelectable()?locator.x - 1:locator.x, ly,
                    isSelectable()?lineExtent.x + 1:lineExtent.x,
                    lineHeight - descent + 3);
            //int lineY = ly + lineHeight - descent + 1;
            areaRectangles.add(new AreaRectangle(br, lineStart, lastLoc));
            locator.x += lastWidth;
            locator.rowHeight = Math.max(locator.rowHeight, lineExtent.y);
        }
        if (oldFont !is null) {
            gc.setFont(oldFont);
        }
    }

    private void computeTextFragments(GC gc) {
        if (textFragments !is null)
            return;
        ArrayList list = new ArrayList();
        auto wb =  UBreakIterator.openLineIterator( ULocale.Default, getText() );
        scope(exit) wb.close();
        int cursor = 0;
        for (int loc = wb.first(); loc !is UBreakIterator.Done; loc = wb.next()) {
            if (loc is 0)
                continue;
            String word = text.substring(cursor, loc);
            Point extent = gc.textExtent(word);
            list.add(new TextFragment(cast(short) loc, cast(short) extent.x));
            cursor = loc;
        }
        textFragments = arraycast!(TextFragment)(list.toArray());
    }

    public void clearCache(String fontId) {
        if (fontId is null && (this.fontId is null||this.fontId.equals(FormTextModel.BOLD_FONT_ID)))
            textFragments = null;
        else if (fontId !is null && this.fontId !is null && fontId.equals(this.fontId))
            textFragments = null;
    }
}
