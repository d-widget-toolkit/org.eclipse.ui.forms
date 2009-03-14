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
module org.eclipse.ui.forms.widgets.SharedScrolledComposite;

import org.eclipse.ui.forms.widgets.SizeCache;

import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.ScrolledComposite;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.ScrollBar;
import org.eclipse.ui.internal.forms.widgets.FormUtil;

import java.lang.all;
import java.util.Set;

/**
 * This class is used to provide common scrolling services to a number of
 * controls in the toolkit. Classes that extend it are not required to implement
 * any method.
 *
 * @since 3.0
 */
public abstract class SharedScrolledComposite : ScrolledComposite {
    private static const int H_SCROLL_INCREMENT = 5;

    private static const int V_SCROLL_INCREMENT = 64;

    private bool ignoreLayouts = true;

    private bool ignoreResizes = false;

    private bool expandHorizontal = false;

    private bool expandVertical = false;

    private SizeCache contentCache;

    private bool reflowPending = false;

    private bool delayedReflow = true;

    /**
     * Creates the new instance.
     *
     * @param parent
     *            the parent composite
     * @param style
     *            the style to use
     */
    public this(Composite parent, int style) {
        contentCache = new SizeCache();
        super(parent, style);
        addListener(SWT.Resize, new class Listener {
            public void handleEvent(Event e) {
                if (!ignoreResizes) {
                    scheduleReflow(false);
                }
            }
        });
        initializeScrollBars();
    }

    /**
     * Sets the foreground of the control and its content.
     *
     * @param fg
     *            the new foreground color
     */
    public void setForeground(Color fg) {
        super.setForeground(fg);
        if (getContent() !is null)
            getContent().setForeground(fg);
    }

    /**
     * Sets the background of the control and its content.
     *
     * @param bg
     *            the new background color
     */
    public void setBackground(Color bg) {
        super.setBackground(bg);
        if (getContent() !is null)
            getContent().setBackground(bg);
    }

    /**
     * Sets the font of the form. This font will be used to render the title
     * text. It will not affect the body.
     */
    public void setFont(Font font) {
        super.setFont(font);
        if (getContent() !is null)
            getContent().setFont(font);
    }

    /**
     * Overrides 'super' to pass the proper colors and font
     */
    public void setContent(Control content) {
        super.setContent(content);
        if (content !is null) {
            content.setForeground(getForeground());
            content.setBackground(getBackground());
            content.setFont(getFont());
        }
    }

    /**
     * If content is set, transfers focus to the content.
     */
    public bool setFocus() {
        bool result;
        FormUtil.setFocusScrollingEnabled(this, false);
        if (getContent() !is null)
            result = getContent().setFocus();
        else
            result = super.setFocus();
        FormUtil.setFocusScrollingEnabled(this, true);
        return result;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.swt.widgets.Composite#layout(bool)
     */
    public void layout(bool changed) {
        if (ignoreLayouts) {
            return;
        }

        ignoreLayouts = true;
        ignoreResizes = true;
        super.layout(changed);
        ignoreResizes = false;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.swt.custom.ScrolledComposite#setExpandHorizontal(bool)
     */
    public void setExpandHorizontal(bool expand) {
        expandHorizontal = expand;
        super.setExpandHorizontal(expand);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.swt.custom.ScrolledComposite#setExpandVertical(bool)
     */
    public void setExpandVertical(bool expand) {
        expandVertical = expand;
        super.setExpandVertical(expand);
    }

    /**
     * Recomputes the body layout and the scroll bars. The method should be used
     * when changes somewhere in the form body invalidate the current layout
     * and/or scroll bars.
     *
     * @param flushCache
     *            if <code>true</code>, drop the cached data
     */
    public void reflow(bool flushCache) {
        Composite c = cast(Composite) getContent();
        Rectangle clientArea = getClientArea();
        if (c is null)
            return;

        contentCache.setControl(c);
        if (flushCache) {
            contentCache.flush();
        }
        try {
            setRedraw(false);
            Point newSize = contentCache.computeSize(FormUtil.getWidthHint(
                    clientArea.width, c), FormUtil.getHeightHint(clientArea.height,
                    c));

            // Point currentSize = c.getSize();
            if (!(expandHorizontal && expandVertical)) {
                c.setSize(newSize);
            }

            setMinSize(newSize);
            FormUtil.updatePageIncrement(this);

            // reduce vertical scroll increment if necessary
            ScrollBar vbar = getVerticalBar();
            if (vbar !is null) {
                if (getClientArea().height - 5 < V_SCROLL_INCREMENT)
                    getVerticalBar().setIncrement(getClientArea().height - 5);
                else
                    getVerticalBar().setIncrement(V_SCROLL_INCREMENT);
            }

            ignoreLayouts = false;
            layout(flushCache);
            ignoreLayouts = true;

            contentCache.layoutIfNecessary();
        } finally {
            setRedraw(true);
        }
    }

    private void updateSizeWhilePending() {
        Control c = getContent();
        Rectangle area = getClientArea();
        setMinSize(area.width, c.getSize().y);
    }

    private void handleScheduleReflow(bool flushCache) {
        if (!isDisposed())
            reflow(flushCache);
        reflowPending = false;
    }
    private void scheduleReflow(bool flushCache) {
        if (delayedReflow) {
            if (reflowPending) {
                updateSizeWhilePending();
                return;
            }
            getDisplay().asyncExec( dgRunnable( &handleScheduleReflow, flushCache));
            reflowPending = true;
        } else
            reflow(flushCache);
    }

    private void initializeScrollBars() {
        ScrollBar hbar = getHorizontalBar();
        if (hbar !is null) {
            hbar.setIncrement(H_SCROLL_INCREMENT);
        }
        ScrollBar vbar = getVerticalBar();
        if (vbar !is null) {
            vbar.setIncrement(V_SCROLL_INCREMENT);
        }
        FormUtil.updatePageIncrement(this);
    }

    /**
     * Tests if the control uses delayed reflow.
     * @return <code>true</code> if reflow requests will
     * be delayed, <code>false</code> otherwise.
     */
    public bool isDelayedReflow() {
        return delayedReflow;
    }

    /**
     * Sets the delayed reflow feature. When used,
     * it will schedule a reflow on resize requests
     * and reject subsequent reflows until the
     * scheduled one is performed. This improves
     * performance by
     * @param delayedReflow
     *            The delayedReflow to set.
     */
    public void setDelayedReflow(bool delayedReflow) {
        this.delayedReflow = delayedReflow;
    }
}
