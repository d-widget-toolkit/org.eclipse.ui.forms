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
module org.eclipse.ui.forms.widgets.AbstractHyperlink;


import org.eclipse.swt.SWT;
import org.eclipse.swt.accessibility.ACC;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.core.runtime.ListenerList;
import org.eclipse.ui.forms.events.HyperlinkEvent;
import org.eclipse.ui.forms.events.IHyperlinkListener;
import org.eclipse.ui.internal.forms.widgets.FormsResources;

import java.lang.all;
import java.util.Set;

/**
 * This is the base class for custom hyperlink widget. It is responsible for
 * processing mouse and keyboard events, and converting them into unified
 * hyperlink events. Subclasses are responsible for rendering the hyperlink in
 * the client area.
 *
 * @since 3.0
 */
public abstract class AbstractHyperlink : Canvas {
    private bool hasFocus;
    bool paintFocus=true;

    /*
     * Armed link is one that will activate on a mouse up event, i.e.
     * it has received a mouse down and mouse still on top of it.
     */
    private bool armed;

    private ListenerList listeners;

    /**
     * Amount of the margin width around the hyperlink (default is 1).
     */
    protected int marginWidth = 1;

    /**
     * Amount of the margin height around the hyperlink (default is 1).
     */
    protected int marginHeight = 1;

    /**
     * Creates a new hyperlink in the provided parent.
     *
     * @param parent
     *            the control parent
     * @param style
     *            the widget style
     */
    public this(Composite parent, int style) {
        super(parent, style);
        addListener(SWT.KeyDown, new class Listener {
            public void handleEvent(Event e) {
                if (e.character is '\r') {
                    handleActivate(e);
                }
            }
        });
        addPaintListener(new class PaintListener {
            public void paintControl(PaintEvent e) {
                paint(e);
            }
        });
        addListener(SWT.Traverse, new class Listener {
            public void handleEvent(Event e) {
                switch (e.detail) {
                case SWT.TRAVERSE_PAGE_NEXT:
                case SWT.TRAVERSE_PAGE_PREVIOUS:
                case SWT.TRAVERSE_ARROW_NEXT:
                case SWT.TRAVERSE_ARROW_PREVIOUS:
                case SWT.TRAVERSE_RETURN:
                    e.doit = false;
                    return;
                default:
                }
                e.doit = true;
            }
        });
        Listener listener = new class Listener {
            public void handleEvent(Event e) {
                switch (e.type) {
                case SWT.FocusIn:
                    hasFocus = true;
                    handleEnter(e);
                    break;
                case SWT.FocusOut:
                    hasFocus = false;
                    handleExit(e);
                    break;
                case SWT.DefaultSelection:
                    handleActivate(e);
                    break;
                case SWT.MouseEnter:
                    handleEnter(e);
                    break;
                case SWT.MouseExit:
                    handleExit(e);
                    break;
                case SWT.MouseDown:
                    handleMouseDown(e);
                    break;
                case SWT.MouseUp:
                    handleMouseUp(e);
                    break;
                case SWT.MouseMove:
                    handleMouseMove(e);
                    break;
                default:
                }
            }
        };
        addListener(SWT.MouseEnter, listener);
        addListener(SWT.MouseExit, listener);
        addListener(SWT.MouseDown, listener);
        addListener(SWT.MouseUp, listener);
        addListener(SWT.MouseMove, listener);
        addListener(SWT.FocusIn, listener);
        addListener(SWT.FocusOut, listener);
        setCursor(FormsResources.getHandCursor());
    }

    /**
     * Adds the event listener to this hyperlink.
     *
     * @param listener
     *            the event listener to add
     */
    public void addHyperlinkListener(IHyperlinkListener listener) {
        if (listeners is null)
            listeners = new ListenerList();
        listeners.add(cast(Object)listener);
    }

    /**
     * Removes the event listener from this hyperlink.
     *
     * @param listener
     *            the event listener to remove
     */
    public void removeHyperlinkListener(IHyperlinkListener listener) {
        if (listeners is null)
            return;
        listeners.remove(cast(Object)listener);
    }

    /**
     * Returns the selection state of the control. When focus is gained, the
     * state will be <samp>true </samp>; it will switch to <samp>false </samp>
     * when the control looses focus.
     *
     * @return <code>true</code> if the widget has focus, <code>false</code>
     *         otherwise.
     */
    public bool getSelection() {
        return hasFocus;
    }

    /**
     * Called when hyperlink is entered. Subclasses that override this method
     * must call 'super'.
     */
    protected void handleEnter(Event e) {
        redraw();
        if (listeners is null)
            return;
        int size = listeners.size();
        HyperlinkEvent he = new HyperlinkEvent(this, getHref(), getText(),
                e.stateMask);
        Object[] listenerList = listeners.getListeners();
        for (int i = 0; i < size; i++) {
            IHyperlinkListener listener = cast(IHyperlinkListener) listenerList[i];
            listener.linkEntered(he);
        }
    }

    /**
     * Called when hyperlink is exited. Subclasses that override this method
     * must call 'super'.
     */
    protected void handleExit(Event e) {
        // disarm the link; won't activate on mouseup
        armed = false;
        redraw();
        if (listeners is null)
            return;
        int size = listeners.size();
        HyperlinkEvent he = new HyperlinkEvent(this, getHref(), getText(),
                e.stateMask);
        Object[] listenerList = listeners.getListeners();
        for (int i = 0; i < size; i++) {
            IHyperlinkListener listener = cast(IHyperlinkListener) listenerList[i];
            listener.linkExited(he);
        }
    }

    /**
     * Called when hyperlink has been activated. Subclasses that override this
     * method must call 'super'.
     */
    protected void handleActivate(Event e) {
        // disarm link, back to normal state
        armed = false;
        getAccessible().setFocus(ACC.CHILDID_SELF);
        if (listeners is null)
            return;
        int size = listeners.size();
        setCursor(FormsResources.getBusyCursor());
        HyperlinkEvent he = new HyperlinkEvent(this, getHref(), getText(),
                e.stateMask);
        Object[] listenerList = listeners.getListeners();
        for (int i = 0; i < size; i++) {
            IHyperlinkListener listener = cast(IHyperlinkListener) listenerList[i];
            listener.linkActivated(he);
        }
        if (!isDisposed())
            setCursor(FormsResources.getHandCursor());
    }

    /**
     * Sets the object associated with this hyperlink. Concrete implementation
     * of this class can use if to store text, URLs or model objects that need
     * to be processed on hyperlink events.
     *
     * @param href
     *            the hyperlink object reference
     */
    public void setHref(Object href) {
        setData("href", href); //$NON-NLS-1$
    }

    /**
     * Returns the object associated with this hyperlink.
     *
     * @see #setHref
     * @return the hyperlink object reference
     */
    public Object getHref() {
        return getData("href"); //$NON-NLS-1$
    }

    /**
     * Returns the textual representation of this hyperlink suitable for showing
     * in tool tips or on the status line.
     *
     * @return the hyperlink text
     */
    public String getText() {
        return getToolTipText();
    }

    /**
     * Paints the hyperlink as a reaction to the provided paint event.
     *
     * @param gc
     *            graphic context
     */
    protected abstract void paintHyperlink(GC gc);

    /**
     * Paints the control as a reaction to the provided paint event.
     *
     * @param e
     *            the paint event
     */
    protected void paint(PaintEvent e) {
        GC gc = e.gc;
        Rectangle clientArea = getClientArea();
        if (clientArea.width is 0 || clientArea.height is 0)
            return;
        paintHyperlink(gc);
        if (paintFocus && hasFocus) {
            Rectangle carea = getClientArea();
            gc.setForeground(getForeground());
            gc.drawFocus(0, 0, carea.width, carea.height);
        }
    }

    private void handleMouseDown(Event e) {
        if (e.button !is 1)
            return;
        // armed and ready to activate on mouseup
        armed = true;
    }

    private void handleMouseUp(Event e) {
        if (!armed || e.button !is 1)
            return;
        Point size = getSize();
        // Filter out mouse up events outside
        // the link. This can happen when mouse is
        // clicked, dragged outside the link, then
        // released.
        if (e.x < 0)
            return;
        if (e.y < 0)
            return;
        if (e.x >= size.x)
            return;
        if (e.y >= size.y)
            return;
        handleActivate(e);
    }

    private void handleMouseMove(Event e) {
        // disarm link if we move out of bounds
        if (armed) {
            Point size = getSize();
            armed = (e.x >= 0 && e.y >= 0 && e.x < size.x && e.y < size.y);
        }
    }

    /*
     * (non-Javadoc)
     * @see org.eclipse.swt.widgets.Control#setEnabled(bool)
     */

    public void setEnabled (bool enabled) {
        super.setEnabled(enabled);
        redraw();
    }
}
