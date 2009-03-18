/*******************************************************************************
 * Copyright (c) 2000, 2007 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Michael Williamson (eclipse-bugs@magnaworks.com) - patch (see Bugzilla #92545)
 *
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/
module org.eclipse.ui.forms.widgets.Section;

import org.eclipse.ui.forms.widgets.ExpandableComposite;
import org.eclipse.ui.forms.widgets.SharedScrolledComposite;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Text;
import org.eclipse.core.runtime.Assert;
import org.eclipse.ui.internal.forms.widgets.FormImages;
import org.eclipse.ui.internal.forms.widgets.FormUtil;

import java.lang.all;
import java.util.Hashtable;
import java.util.Set;

/**
 * A variation of the expandable composite that adds optional description below
 * the title. Section is often used as a basic building block in forms because
 * it provides for logical grouping of information.
 * <p>
 * In case of the TITLE_BAR style, Section renders the title bar in a way
 * compatible with the rest of the workbench. Since it is a widget, all the
 * colors must be supplied directly. When created by the form toolkit, these
 * colors are supplied by the toolkit. The toolkit initializes these colors
 * based on the system colors. For this reason, it is recommended to create the
 * section by the toolkit instead of through its own constructor.
 * <p>
 * Since 3.1, it is possible to set a control to be used for section
 * description. If used, <code>DESCRIPTION</code> style should not be set. A
 * typical way to take advantage of the new method is to set an instance of
 * <code>FormText</code> to provide for hyperlinks and images in the
 * description area.
 *
 * @since 3.0
 */
public class Section : ExpandableComposite {
    /**
     * Description style. If used, description will be rendered below the title.
     */
    public static const int DESCRIPTION = 1 << 7;

    private Control descriptionControl;

    private Control separator;

    private Hashtable titleColors;

    private static const String COLOR_BG = "bg"; //$NON-NLS-1$

    private static const String COLOR_GBG = "gbg"; //$NON-NLS-1$

    private static const String COLOR_BORDER = "border"; //$NON-NLS-1$

    /**
     * Creates a new section instance in the provided parent.
     *
     * @param parent
     *            the parent composite
     * @param style
     *            the style to use
     */
    public this(Composite parent, int style) {
        this(parent, SWT.NULL, style);
    }

    this(Composite parent, int cstyle, int style) {
        super(parent, cstyle | getBackgroundStyle(style), style);
        int rtl = cstyle & SWT.RIGHT_TO_LEFT;
        if ((style & DESCRIPTION) !is 0) {
            descriptionControl = new Text(this, SWT.READ_ONLY | SWT.WRAP | rtl);
        }
        if ((style & TITLE_BAR) !is 0) {
            Listener listener = new class Listener{
                public void handleEvent(Event e) {
                    Image image = this.outer.callSuperGetBackgroundImage();
                    if (image !is null) {
                        FormImages.getInstance().markFinished(image);
                    }
                    this.outer.callSuperSetBackgroundImage(null);
                }
            };
            addListener(SWT.Dispose, listener);
            addListener(SWT.Resize, listener);
        }
    }

    private static int getBackgroundStyle(int estyle) {
        return ((estyle & TITLE_BAR) !is 0) ? SWT.NO_BACKGROUND : SWT.NULL;
    }

    private Image callSuperGetBackgroundImage(){
        return super.getBackgroundImage();
    }
    private void callSuperSetBackgroundImage(Image image){
        return super.setBackgroundImage(image);
    }
    protected void internalSetExpanded(bool expanded) {
        super.internalSetExpanded(expanded);
        if ((getExpansionStyle() & TITLE_BAR) !is 0) {
            if (!expanded)
                super.setBackgroundImage(cast(Image)null);
        }
        reflow();
    }

    /**
     * Reflows this section and all the parents up the hierarchy until a
     * SharedScrolledComposite is reached.
     */
    protected void reflow() {
        Composite c = this;
        while (c !is null) {
            c.setRedraw(false);
            c = c.getParent();
            if (null !is cast(SharedScrolledComposite)c ) {
                break;
            }
        }
        c = this;
        while (c !is null) {
            c.layout(true);
            c = c.getParent();
            if (null !is cast(SharedScrolledComposite)c ) {
                (cast(SharedScrolledComposite) c).reflow(true);
                break;
            }
        }
        c = this;
        while (c !is null) {
            c.setRedraw(true);
            c = c.getParent();
            if (null !is cast(SharedScrolledComposite)c ) {
                break;
            }
        }
    }

    /**
     * Sets the description text. Has no effect if DESCRIPTION style was not
     * used to create the control.
     *
     * @param description
     */
    public void setDescription(String description) {
        if (null !is cast(Text)descriptionControl )
            (cast(Text) descriptionControl).setText(description);
    }

    /**
     * Returns the current description text.
     *
     * @return description text or <code>null</code> if DESCRIPTION style was
     *         not used to create the control.
     */
    public String getDescription() {
        if (null !is cast(Text)descriptionControl )
            return (cast(Text) descriptionControl).getText();
        return null;
    }

    /**
     * Sets the separator control of this section. The separator must not be
     * <samp>null </samp> and must be a direct child of this container. If
     * defined, separator will be placed below the title text and will remain
     * visible regardless of the expansion state.
     *
     * @param separator
     *            the separator that will be placed below the title text.
     */
    public void setSeparatorControl(Control separator) {
        Assert.isTrue(separator !is null && separator.getParent().opEquals(this));
        this.separator = separator;
    }

    /**
     * Returns the control that is used as a separator betweeen the title and
     * the client, or <samp>null </samp> if not set.
     *
     * @return separator control or <samp>null </samp> if not set.
     */
    public Control getSeparatorControl() {
        return separator;
    }

    /**
     * Sets the background of the section.
     *
     * @param bg
     *            the new background
     */
    public void setBackground(Color bg) {
        super.setBackground(bg);
        if (descriptionControl !is null
                && (getExpansionStyle() & DESCRIPTION) !is 0)
            descriptionControl.setBackground(bg);
    }

    /**
     * Sets the foreground of the section.
     *
     * @param fg
     *            the new foreground.
     */
    public void setForeground(Color fg) {
        super.setForeground(fg);
        if (descriptionControl !is null
                && (getExpansionStyle() & DESCRIPTION) !is 0)
            descriptionControl.setForeground(fg);
    }

    /**
     * Returns the control used to render the description. In 3.1, this method
     * was promoted to public.
     *
     * @return description control or <code>null</code> if DESCRIPTION style
     *         was not used to create the control and description control was
     *         not set by the client.
     * @see #setDescriptionControl(org.eclipse.swt.widgets.Control)
     */
    public Control getDescriptionControl() {
        return descriptionControl;
    }

    /**
     * Sets the description control of this section. The control must not be
     * <samp>null</samp> and must be a direct child of this container. If
     * defined, contol will be placed below the title text and the separator and
     * will be hidden int he collapsed state.
     * <p>
     * This method and <code>DESCRIPTION</code> style are mutually exclusive.
     * Use the method only if you want to create the description control
     * yourself.
     *
     * @since 3.1
     * @param descriptionControl
     *            the control that will be placed below the title text.
     */
    public void setDescriptionControl(Control descriptionControl) {
        Assert.isTrue((getExpansionStyle() & DESCRIPTION) is 0);
        Assert.isTrue(descriptionControl !is null
                && descriptionControl.getParent().opEquals(this));
        this.descriptionControl = descriptionControl;
    }

    /**
     * Sets the color of the title bar border when TITLE_BAR style is used.
     *
     * @param color
     *            the title bar border color
     */
    public void setTitleBarBorderColor(Color color) {
        putTitleBarColor(COLOR_BORDER, color);
    }

    /**
     * Sets the color of the title bar background when TITLE_BAR style is used.
     * This color is used as a starting color for the vertical gradient.
     *
     * @param color
     *            the title bar border background
     */
    public void setTitleBarBackground(Color color) {
        putTitleBarColor(COLOR_BG, color);
    }

    /**
     * Sets the color of the title bar gradient background when TITLE_BAR style
     * is used. This color is used at the height where title controls end
     * (toggle, tool bar).
     *
     * @param color
     *            the title bar gradient background
     */
    public void setTitleBarGradientBackground(Color color) {
        putTitleBarColor(COLOR_GBG, color);
    }

    /**
     * Returns the title bar border color when TITLE_BAR style is used.
     *
     * @return the title bar border color
     */
    public Color getTitleBarBorderColor() {
        if (titleColors is null)
            return null;
        return cast(Color) titleColors.get(COLOR_BORDER);
    }

    /**
     * Returns the title bar gradient background color when TITLE_BAR style is
     * used.
     *
     * @return the title bar gradient background
     */
    public Color getTitleBarGradientBackground() {
        if (titleColors is null)
            return null;
        if ((getExpansionStyle() & SHORT_TITLE_BAR) !is 0)
            return getBackground();
        return cast(Color) titleColors.get(COLOR_GBG);
    }

    /**
     * Returns the title bar background when TITLE_BAR style is used.
     *
     * @return the title bar background
     */
    public Color getTitleBarBackground() {
        if (titleColors is null)
            return null;
        return cast(Color) titleColors.get(COLOR_BG);
    }

    private void putTitleBarColor(String key, Color color) {
        if (color is null)
            return;
        if (titleColors is null)
            titleColors = new Hashtable();
        titleColors.put(key, color);
    }

    protected void onPaint(PaintEvent e) {
        Color bg = null;
        Color fg = null;
        Color border = null;

        GC gc = e.gc;
        Image buffer = null;
        Rectangle bounds = getClientArea();

        if ((getExpansionStyle() & TITLE_BAR) !is 0) {
            buffer = new Image(getDisplay(), bounds.width, bounds.height);
            buffer.setBackground(getBackground());
            gc = new GC(buffer);
        }
        if (titleColors !is null) {
            bg = cast(Color) titleColors.get(COLOR_BG);
            fg = getTitleBarForeground();
            border = cast(Color) titleColors.get(COLOR_BORDER);
        }
        if (bg is null)
            bg = getBackground();
        if (fg is null)
            fg = getForeground();
        if (border is null)
            border = fg;
        int theight = 0;
        int gradientheight = 0;
        int tvmargin = IGAP;
        if ((getExpansionStyle() & TITLE_BAR) !is 0) {
            Point tsize = null;
            Point tcsize = null;
            if (toggle !is null)
                tsize = toggle.getSize();
            int twidth = bounds.width - marginWidth - marginWidth;
            if (tsize !is null)
                twidth -= tsize.x + IGAP;
            if (getTextClient() !is null)
                tcsize = getTextClient().getSize();
            if (tcsize !is null)
                twidth -= tcsize.x + IGAP;
            Point size = textLabel.getSize();
            if (tsize !is null)
                theight += Math.max(theight, tsize.y);
            gradientheight = theight;
            if (tcsize !is null) {
                theight = Math.max(theight, tcsize.y);
            }
            theight = Math.max(theight, size.y);
            gradientheight = Math.max(gradientheight, size.y);
            theight += tvmargin + tvmargin;
            gradientheight += tvmargin + tvmargin;
        } else {
            theight = 5;
        }
        if ((getExpansionStyle() & TITLE_BAR) !is 0) {
            if (getBackgroundImage() is null)
                updateHeaderImage(bg, bounds, gradientheight, theight);
            gc.setBackground(getBackground());
            gc.fillRectangle(bounds.x, bounds.y, bounds.width, bounds.height);
            drawBackground(gc, bounds.x, bounds.y, bounds.width, theight);
            if (marginWidth > 0) {
                // fix up margins
                gc.setBackground(getBackground());
                gc.fillRectangle(0, 0, marginWidth, theight);
                gc.fillRectangle(bounds.x + bounds.width - marginWidth, 0,
                        marginWidth, theight);
            }
        } else if (isExpanded()) {
            gc.setForeground(bg);
            gc.setBackground(getBackground());
            gc.fillGradientRectangle(marginWidth, marginHeight, bounds.width
                    - marginWidth - marginWidth, theight, true);
        }
        gc.setBackground(getBackground());
        FormUtil.setAntialias(gc, SWT.ON);
        // repair the upper left corner
        gc.fillPolygon([ marginWidth, marginHeight, marginWidth,
                marginHeight + 2, marginWidth + 2, marginHeight ]);
        // repair the upper right corner
        gc.fillPolygon([ bounds.width - marginWidth - 3,
                marginHeight, bounds.width - marginWidth, marginHeight,
                bounds.width - marginWidth, marginHeight + 3 ]);
        gc.setForeground(border);
        if (isExpanded() || (getExpansionStyle() & TITLE_BAR) !is 0) {
            // top left curve
            gc.drawLine(marginWidth, marginHeight + 2, marginWidth + 2,
                    marginHeight);
            // top edge
            gc.drawLine(marginWidth + 2, marginHeight, bounds.width
                    - marginWidth - 3, marginHeight);
            // top right curve
            gc.drawLine(bounds.width - marginWidth - 3, marginHeight,
                    bounds.width - marginWidth - 1, marginHeight + 2);
        } else {
            // collapsed short title bar
            // top edge
            gc.drawLine(marginWidth, marginHeight, bounds.width - 1,
                    marginHeight);
        }
        if ((getExpansionStyle() & TITLE_BAR) !is 0 || isExpanded()) {
            // left vertical edge gradient
            gc.fillGradientRectangle(marginWidth, marginHeight + 2, 1,
                    gradientheight - 2, true);
            // right vertical edge gradient
            gc.fillGradientRectangle(bounds.width - marginWidth - 1,
                    marginHeight + 2, 1, gradientheight - 2, true);
        }
        if ((getExpansionStyle() & TITLE_BAR) !is 0) {
            // New in 3.3 - edge treatmant
            gc.setForeground(getDisplay().getSystemColor(SWT.COLOR_WHITE));
            gc.drawPolyline([ marginWidth + 1,
                    marginHeight + gradientheight - 1, marginWidth + 1,
                    marginHeight + 2, marginWidth + 2, marginHeight + 2,
                    marginWidth + 2, marginHeight + 1,
                    bounds.width - marginWidth - 3, marginHeight + 1,
                    bounds.width - marginWidth - 3, marginHeight + 2,
                    bounds.width - marginWidth - 2, marginHeight + 2,
                    bounds.width - marginWidth - 2,
                    marginHeight + gradientheight - 1 ]);
        }
        if (buffer !is null) {
            gc.dispose();
            e.gc.drawImage(buffer, 0, 0);
            buffer.dispose();
        }
    }

    private void updateHeaderImage(Color bg, Rectangle bounds, int theight,
            int realtheight) {
        Image image = FormImages.getInstance().getGradient(getDisplay(), getBackground(), bg, realtheight, theight, marginHeight);
        super.setBackgroundImage(image);
    }

    /**
     * Background image is used for the title gradient - does nothing.
     */
    public final void setBackgroundImage(Image image) {
    }
}
