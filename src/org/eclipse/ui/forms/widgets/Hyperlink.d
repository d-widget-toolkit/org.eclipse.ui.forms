/*******************************************************************************
 * Copyright (c) 2004, 2007 IBM Corporation and others.
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
module org.eclipse.ui.forms.widgets.Hyperlink;

import org.eclipse.ui.forms.widgets.AbstractHyperlink;

import org.eclipse.swt.SWT;
import org.eclipse.swt.accessibility.ACC;
import org.eclipse.swt.accessibility.Accessible;
import org.eclipse.swt.accessibility.AccessibleAdapter;
import org.eclipse.swt.accessibility.AccessibleControlAdapter;
import org.eclipse.swt.accessibility.AccessibleControlEvent;
import org.eclipse.swt.accessibility.AccessibleEvent;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Composite;

import org.eclipse.ui.internal.forms.widgets.FormUtil;

import java.lang.all;
import java.util.Set;

/**
 * Hyperlink is a concrete implementation of the abstract base class that draws
 * text in the client area. Text can be wrapped and underlined. Hyperlink is
 * typically added to the hyperlink group so that certain properties are managed
 * for all the hyperlinks that belong to it.
 * <p>
 * Hyperlink can be extended.
 *
 * @see org.eclipse.ui.forms.HyperlinkGroup
 * @since 3.0
 */
public class Hyperlink : AbstractHyperlink {
    private String text;
    private static const String ELLIPSIS = "..."; //$NON-NLS-1$
    private bool underlined;
    // The tooltip is used for two purposes - the application can set
    // a tooltip or the tooltip can be used to display the full text when the
    // the text has been truncated due to the label being too short.
    // The appToolTip stores the tooltip set by the application.  Control.tooltiptext
    // contains whatever tooltip is currently being displayed.
    private String appToolTipText;

    /**
     * Creates a new hyperlink control in the provided parent.
     *
     * @param parent
     *            the control parent
     * @param style
     *            the widget style
     */
    public this(Composite parent, int style) {
        super(parent, style);
        initAccessible();
    }

    protected void initAccessible() {
        Accessible accessible = getAccessible();
        accessible.addAccessibleListener(new class AccessibleAdapter {
            public void getName(AccessibleEvent e) {
                e.result = getText();
                if (e.result is null)
                    getHelp(e);
            }

            public void getHelp(AccessibleEvent e) {
                e.result = getToolTipText();
            }
        });
        accessible.addAccessibleControlListener(new class AccessibleControlAdapter {
            public void getChildAtPoint(AccessibleControlEvent e) {
                Point pt = toControl(new Point(e.x, e.y));
                e.childID = (getBounds().contains(pt)) ? ACC.CHILDID_SELF
                        : ACC.CHILDID_NONE;
            }

            public void getLocation(AccessibleControlEvent e) {
                Rectangle location = getBounds();
                Point pt = toDisplay(new Point(location.x, location.y));
                e.x = pt.x;
                e.y = pt.y;
                e.width = location.width;
                e.height = location.height;
            }

            public void getChildCount(AccessibleControlEvent e) {
                e.detail = 0;
            }

            public void getRole(AccessibleControlEvent e) {
                e.detail = ACC.ROLE_LINK;
            }

            public void getDefaultAction (AccessibleControlEvent e) {
                e.result = SWT.getMessage ("SWT_Press"); //$NON-NLS-1$
            }

            public void getState(AccessibleControlEvent e) {
                int state = ACC.STATE_NORMAL;
                if (this.outer.getSelection())
                    state = ACC.STATE_SELECTED | ACC.STATE_FOCUSED;
                e.detail = state;
            }
        });
    }

    /**
     * Sets the underlined state. It is not necessary to call this method when
     * in a hyperlink group.
     *
     * @param underlined
     *            if <samp>true </samp>, a line will be drawn below the text for
     *            each wrapped line.
     */
    public void setUnderlined(bool underlined) {
        this.underlined = underlined;
        redraw();
    }

    /**
     * Returns the underline state of the hyperlink.
     *
     * @return <samp>true </samp> if text is underlined, <samp>false </samp>
     *         otherwise.
     */
    public bool isUnderlined() {
        return underlined;
    }

    /**
     * Overrides the parent by incorporating the margin.
     */
    public Point computeSize(int wHint, int hHint, bool changed) {
        checkWidget();
        int innerWidth = wHint;
        if (innerWidth !is SWT.DEFAULT)
            innerWidth -= marginWidth * 2;
        Point textSize = computeTextSize(innerWidth, hHint);
        int textWidth = textSize.x + 2 * marginWidth;
        int textHeight = textSize.y + 2 * marginHeight;
        return new Point(textWidth, textHeight);
    }

    /**
     * Returns the current hyperlink text.
     *
     * @return hyperlink text
     */
    public String getText() {
        return text;
    }

    /* (non-Javadoc)
     * @see org.eclipse.swt.widgets.Control#getToolTipText()
     */
    public String getToolTipText () {
        checkWidget();
        return appToolTipText;
    }

    /* (non-Javadoc)
     * @see org.eclipse.swt.widgets.Control#setToolTipText(java.lang.String)
     */
    public void setToolTipText (String string) {
        super.setToolTipText (string);
        appToolTipText = super.getToolTipText();
    }

    /**
     * Sets the text of this hyperlink.
     *
     * @param text
     *            the hyperlink text
     */
    public void setText(String text) {
        if (text !is null)
            this.text = text;
        else
            this.text = ""; //$NON-NLS-1$
        redraw();
    }

    /**
     * Paints the hyperlink text.
     *
     * @param gc
     *            graphic context
     */
    protected void paintHyperlink(GC gc) {
        Rectangle carea = getClientArea();
        Rectangle bounds = new Rectangle(marginWidth, marginHeight, carea.width
                - marginWidth - marginWidth, carea.height - marginHeight
                - marginHeight);
        paintText(gc, bounds);
    }

    /**
     * Paints the hyperlink text in provided bounding rectangle.
     *
     * @param gc
     *            graphic context
     * @param bounds
     *            the bounding rectangle in which to paint the text
     */
    protected void paintText(GC gc, Rectangle bounds) {
        gc.setFont(getFont());
        gc.setForeground(getForeground());
        if ((getStyle() & SWT.WRAP) !is 0) {
            FormUtil.paintWrapText(gc, text, bounds, underlined);
        } else {
            Point totalSize = computeTextSize(SWT.DEFAULT, SWT.DEFAULT);
            bool shortenText_ =false;
            if (bounds.width<totalSize.x) {
                // shorten
                shortenText_=true;
            }
            int textWidth = Math.min(bounds.width, totalSize.x);
            int textHeight = totalSize.y;
            String textToDraw = getText();
            if (shortenText_) {
                textToDraw = shortenText(gc, getText(), bounds.width);
                if (appToolTipText is null) {
                    super.setToolTipText(getText());
                }
            }
            else {
                super.setToolTipText(appToolTipText);
            }
            gc.drawText(textToDraw, bounds.x, bounds.y, true);
            if (underlined) {
                int descent = gc.getFontMetrics().getDescent();
                int lineY = bounds.y + textHeight - descent + 1;
                gc.drawLine(bounds.x, lineY, bounds.x + textWidth, lineY);
            }
        }
    }

    protected String shortenText(GC gc, String t, int width) {
        if (t is null) return null;
        int w = gc.textExtent(ELLIPSIS).x;
        if (width<=w) return t;
        int l = t.length;
        int max = l/2;
        int min = 0;
        int mid = (max+min)/2 - 1;
        if (mid <= 0) return t;
        while (min < mid && mid < max) {
            String s1 = t.substring(0, mid);
            String s2 = t.substring(l-mid, l);
            int l1 = gc.textExtent(s1).x;
            int l2 = gc.textExtent(s2).x;
            if (l1+w+l2 > width) {
                max = mid;
                mid = (max+min)/2;
            } else if (l1+w+l2 < width) {
                min = mid;
                mid = (max+min)/2;
            } else {
                min = max;
            }
        }
        if (mid is 0) return t;
        return t.substring(0, mid)~ELLIPSIS~t.substring(l-mid, l);
    }

    protected Point computeTextSize(int wHint, int hHint) {
        Point extent;
        GC gc = new GC(this);
        gc.setFont(getFont());
        if ((getStyle() & SWT.WRAP) !is 0 && wHint !is SWT.DEFAULT) {
            extent = FormUtil.computeWrapSize(gc, getText(), wHint);
        } else {
            extent = gc.textExtent(getText());
            if ((getStyle() & SWT.WRAP) is 0 && wHint !is SWT.DEFAULT)
                extent.x = wHint;
        }
        gc.dispose();
        return extent;
    }
}
