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
module org.eclipse.ui.forms.widgets.ToggleHyperlink;

import org.eclipse.ui.forms.widgets.AbstractHyperlink;
import org.eclipse.ui.forms.widgets.ExpandableComposite;

import org.eclipse.swt.SWT;
import org.eclipse.swt.accessibility.ACC;
import org.eclipse.swt.accessibility.AccessibleAdapter;
import org.eclipse.swt.accessibility.AccessibleControlAdapter;
import org.eclipse.swt.accessibility.AccessibleControlEvent;
import org.eclipse.swt.accessibility.AccessibleEvent;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.ui.forms.events.HyperlinkAdapter;
import org.eclipse.ui.forms.events.HyperlinkEvent;
import org.eclipse.ui.internal.forms.Messages;

import java.lang.all;
import java.util.Set;

/**
 * A custom selectable control that can be used to control areas that can be
 * expanded or collapsed.
 * <p>
 * This is an abstract class. Subclasses are responsible for rendering the
 * control using decoration and hover decoration color. Control should be
 * rendered based on the current expansion state.
 *
 * @since 3.0
 */
public abstract class ToggleHyperlink : AbstractHyperlink {

    alias AbstractHyperlink.computeSize computeSize;

    protected int innerWidth;
    protected int innerHeight;
    protected bool hover;
    package bool hover_package(){
        return hover;
    }
    package bool hover_package( bool v){
        return (hover = v);
    }
    private bool expanded;
    private Color decorationColor;
    private Color hoverColor;
    /**
     * Creates a control in a provided composite.
     *
     * @param parent
     *            the parent
     * @param style
     *            the style
     */
    public this(Composite parent, int style) {
        super(parent, style);
        Listener listener = new class Listener {
            public void handleEvent(Event e) {
                switch (e.type) {
                    case SWT.MouseEnter:
                        hover=true;
                        redraw();
                        break;
                    case SWT.MouseExit:
                        hover = false;
                        redraw();
                        break;
                    case SWT.KeyDown:
                        onKeyDown(e);
                        break;
                    default:
                }
            }
        };
        addListener(SWT.MouseEnter, listener);
        addListener(SWT.MouseExit, listener);
        addListener(SWT.KeyDown, listener);
        addHyperlinkListener(new class HyperlinkAdapter {
            public void linkActivated(HyperlinkEvent e) {
                setExpanded(!isExpanded());
            }
        });
        initAccessible();
    }
    /**
     * Sets the color of the decoration.
     *
     * @param decorationColor
     */
    public void setDecorationColor(Color decorationColor) {
        this.decorationColor = decorationColor;
    }
    /**
     * Returns the color of the decoration.
     *
     * @return decoration color
     */
    public Color getDecorationColor() {
        return decorationColor;
    }
    /**
     * Sets the hover color of decoration. Hover color will be used when mouse
     * enters the decoration area.
     *
     * @param hoverColor
     *            the hover color to use
     */
    public void setHoverDecorationColor(Color hoverColor) {
        this.hoverColor = hoverColor;
    }
    /**
     * Returns the hover color of the decoration.
     *
     * @return the hover color of the decoration.
     * @since 3.1
     */
    public Color getHoverDecorationColor() {
        return hoverColor;
    }

    /**
     * Returns the hover color of the decoration.
     *
     * @return the hover color of the decoration.
     * @deprecated use <code>getHoverDecorationColor</code>
     * @see #getHoverDecorationColor()
     */
    public Color geHoverDecorationColor() {
        return hoverColor;
    }
    /**
     * Computes the size of the control.
     *
     * @param wHint
     *            width hint
     * @param hHint
     *            height hint
     * @param changed
     *            if true, flush any saved layout state
     */
    public Point computeSize(int wHint, int hHint, bool changed) {
        int width, height;
        /*
        if (wHint !is SWT.DEFAULT)
            width = wHint;
        else */
            width = innerWidth + 2 * marginWidth;
        /*
        if (hHint !is SWT.DEFAULT)
            height = hHint;
        else */
            height = innerHeight + 2 * marginHeight;
        return new Point(width, height);
    }
    /**
     * Returns the expansion state of the toggle control. When toggle is in the
     * normal (downward) state, the value is <samp>true </samp>. Collapsed
     * control will return <samp>false </samp>.
     *
     * @return <samp>false </samp> if collapsed, <samp>true </samp> otherwise.
     */
    public bool isExpanded() {
        return expanded;
    }
    /**
     * Sets the expansion state of the twistie control
     *
     * @param expanded the expansion state
     */
    public void setExpanded(bool expanded) {
        this.expanded = expanded;
        getAccessible().selectionChanged();
        redraw();
    }
    private void initAccessible() {
        getAccessible().addAccessibleListener(new class AccessibleAdapter {
            public void getHelp(AccessibleEvent e) {
                e.result = getToolTipText();
            }
            public void getName(AccessibleEvent e) {
                String name=Messages.ToggleHyperlink_accessibleName;
                if (null !is cast(ExpandableComposite)getParent() ) {
                    name ~= Messages.ToggleHyperlink_accessibleColumn ~ (cast(ExpandableComposite)getParent()).getText();
                    int index = name.indexOf('&');
                    if (index !is -1) {
                        name = name.substring(0, index) ~ name.substring(index + 1);
                    }
                }
                e.result = name;
            }
            public void getDescription(AccessibleEvent e) {
                getName(e);
            }
        });
        getAccessible().addAccessibleControlListener(
                new class AccessibleControlAdapter {
                    public void getChildAtPoint(AccessibleControlEvent e) {
                        Point testPoint = toControl(new Point(e.x, e.y));
                        if (getBounds().contains(testPoint)) {
                            e.childID = ACC.CHILDID_SELF;
                        }
                    }
                    public void getLocation(AccessibleControlEvent e) {
                        Rectangle location = getBounds();
                        Point pt = toDisplay(new Point(location.x, location.y));
                        e.x = pt.x;
                        e.y = pt.y;
                        e.width = location.width;
                        e.height = location.height;
                    }
                    public void getSelection (AccessibleControlEvent e) {
                        if (this.outer.getSelection())
                            e.childID = ACC.CHILDID_SELF;
                    }

                    public void getFocus (AccessibleControlEvent e) {
                        if (this.outer.getSelection())
                            e.childID = ACC.CHILDID_SELF;
                    }
                    public void getChildCount(AccessibleControlEvent e) {
                        e.detail = 0;
                    }
                    public void getRole(AccessibleControlEvent e) {
                        e.detail = ACC.ROLE_TREE;
                    }
                    public void getState(AccessibleControlEvent e) {
                        int state = ACC.STATE_FOCUSABLE;
                        if (this.outer.getSelection())
                            state |= ACC.STATE_FOCUSED;
                        state |= this.outer.isExpanded()
                                ? ACC.STATE_EXPANDED
                                : ACC.STATE_COLLAPSED;
                        e.detail = state;
                    }
                });
    }
    private void onKeyDown(Event e) {
        if (e.keyCode is SWT.ARROW_RIGHT) {
            // expand if collapsed
            if (!isExpanded()) {
                handleActivate(e);
            }
            e.doit=false;
        }
        else if (e.keyCode is SWT.ARROW_LEFT) {
            // collapse if expanded
            if (isExpanded()) {
                handleActivate(e);
            }
            e.doit=false;
        }
    }
}
