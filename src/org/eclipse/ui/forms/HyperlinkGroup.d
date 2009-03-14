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
module org.eclipse.ui.forms.HyperlinkGroup;

import org.eclipse.ui.forms.HyperlinkSettings;

import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.ui.forms.events.HyperlinkEvent;
import org.eclipse.ui.forms.events.IHyperlinkListener;
import org.eclipse.ui.forms.widgets.Hyperlink;

import java.lang.all;
import java.util.ArrayList;
import java.util.Set;

/**
 * Manages a group of hyperlinks. It tracks activation, updates normal and
 * active colors and updates underline state depending on the underline
 * preference. Hyperlink labels are added to the group after creation and are
 * automatically removed from the group when they are disposed.
 *
 * @since 3.0
 */

public final class HyperlinkGroup : HyperlinkSettings {
    private ArrayList links;
    private Hyperlink lastActivated;
    private Hyperlink lastEntered;
    private GroupListener listener;
    private bool isActiveBackgroundSet;
    private bool isActiveForegroundSet;
    private bool isBackgroundSet;
    private bool isForegroundSet;

    private class GroupListener : Listener, IHyperlinkListener {

        private Color previousBackground;
        private Color previousForeground;

        public void handleEvent(Event e) {
            switch (e.type) {
                case SWT.MouseEnter :
                    onMouseEnter(e);
                    break;
                case SWT.MouseExit :
                    onMouseExit(e);
                    break;
                case SWT.MouseDown :
                    onMouseDown(e);
                    break;
                case SWT.Dispose :
                    unhook(cast(Hyperlink) e.widget);
                    break;
                default:
            }
        }
        private void onMouseEnter(Event e) {
            Hyperlink link = cast(Hyperlink) e.widget;
            previousBackground = link.getBackground();
            previousForeground = link.getForeground();
            if (isActiveBackgroundSet)
                link.setBackground(getActiveBackground());
            if (isActiveForegroundSet)
                link.setForeground(getActiveForeground());
            if (getHyperlinkUnderlineMode() is UNDERLINE_HOVER)
                link.setUnderlined(true);
            link.setCursor(getHyperlinkCursor());
        }
        private void onMouseExit(Event e) {
            Hyperlink link = cast(Hyperlink) e.widget;
            if (isActiveBackgroundSet)
                link.setBackground(previousBackground);
            if (isActiveForegroundSet)
                link.setForeground(previousForeground);
            if (getHyperlinkUnderlineMode() is UNDERLINE_HOVER)
                link.setUnderlined(false);
        }
        public void linkActivated(HyperlinkEvent e) {
        }

        public void linkEntered(HyperlinkEvent e) {
            Hyperlink link = cast(Hyperlink) e.widget;
            if (lastEntered !is null) {
                linkExited(lastEntered);
            }
            lastEntered = link;
        }

        public void linkExited(HyperlinkEvent e) {
            linkExited(cast(Hyperlink) e.widget);
        }
        private void linkExited(Hyperlink link) {
            link.setCursor(null);
            if (lastEntered is link)
                lastEntered = null;
        }
    }

    /**
     * Creates a hyperlink group.
     */

    public this(Display display) {
        links = new ArrayList();
        super(display);
        listener = new GroupListener();
    }

    /**
     * Returns the link that has been active the last, or <code>null</code>
     * if no link has been active yet or the last active link has been
     * disposed.
     *
     * @return the last active link or <code>null</code>
     */
    public Hyperlink getLastActivated() {
        return lastActivated;
    }
    /**
     * Adds a hyperlink to the group to be jointly managed. Hyperlink will be
     * managed until it is disposed. Settings like colors, cursors and modes
     * will affect all managed hyperlinks.
     *
     * @param link
     */

    public void add(Hyperlink link) {
        if (isBackgroundSet)
            link.setBackground(getBackground());
        if (isForegroundSet)
            link.setForeground(getForeground());
        if (getHyperlinkUnderlineMode() is UNDERLINE_ALWAYS)
            link.setUnderlined(true);
        hook(link);
    }

    /**
     * Sets the new active hyperlink background for all the links.
     *
     * @param newActiveBackground
     *            the new active background
     */
    public void setActiveBackground(Color newActiveBackground) {
        super.setActiveBackground(newActiveBackground);
        isActiveBackgroundSet = true;
    }

    /**
     * Sets the new active hyperlink foreground for all the links.
     *
     * @param newActiveForeground
     *            the new active foreground
     */
    public void setActiveForeground(Color newActiveForeground) {
        super.setActiveForeground(newActiveForeground);
        isActiveForegroundSet = true;
    }

    /**
     * Sets the group background and also sets the background of all the
     * currently managed links.
     *
     * @param bg
     *            the new background
     */
    public void setBackground(Color bg) {
        super.setBackground(bg);
        isBackgroundSet = true;
        if (links !is null) {
            for (int i = 0; i < links.size(); i++) {
                Hyperlink label = cast(Hyperlink) links.get(i);
                label.setBackground(bg);
            }
        }
    }
    /**
     * Sets the group foreground and also sets the background of all the
     * currently managed links.
     *
     * @param fg
     *            the new foreground
     */
    public void setForeground(Color fg) {
        super.setForeground(fg);
        isForegroundSet = true;
        if (links !is null) {
            for (int i = 0; i < links.size(); i++) {
                Hyperlink label = cast(Hyperlink) links.get(i);
                label.setForeground(fg);
            }
        }
    }
    /**
     * Sets the hyperlink underline mode.
     *
     * @param mode
     *            the new hyperlink underline mode
     * @see HyperlinkSettings
     */
    public void setHyperlinkUnderlineMode(int mode) {
        super.setHyperlinkUnderlineMode(mode);
        if (links !is null) {
            for (int i = 0; i < links.size(); i++) {
                Hyperlink label = cast(Hyperlink) links.get(i);
                label.setUnderlined(mode is UNDERLINE_ALWAYS);
            }
        }
    }

    private void hook(Hyperlink link) {
        link.addListener(SWT.MouseDown, listener);
        link.addHyperlinkListener(listener);
        link.addListener(SWT.Dispose, listener);
        link.addListener(SWT.MouseEnter, listener);
        link.addListener(SWT.MouseExit, listener);
        links.add(link);
    }

    private void unhook(Hyperlink link) {
        link.removeListener(SWT.MouseDown, listener);
        link.removeHyperlinkListener(listener);
        link.removeListener(SWT.MouseEnter, listener);
        link.removeListener(SWT.MouseExit, listener);
        if (lastActivated is link)
            lastActivated = null;
        if (lastEntered is link)
            lastEntered = null;
        links.remove(link);
    }

    private void onMouseDown(Event e) {
        if (e.button is 1)
            return;
        lastActivated = cast(Hyperlink) e.widget;
    }
}
