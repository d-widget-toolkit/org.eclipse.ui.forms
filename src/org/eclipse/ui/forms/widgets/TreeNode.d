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
module org.eclipse.ui.forms.widgets.TreeNode;

import org.eclipse.ui.forms.widgets.ToggleHyperlink;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Composite;

import java.lang.all;
import java.util.Set;

/**
 * A custom selectable control that can be used to control areas that can be
 * expanded or collapsed. The control control can be toggled between selected
 * and deselected state with a mouse or by pressing 'Enter' while the control
 * has focus.
 * <p>
 * The control is rendered as box with a '+' or '-' sign, depending on the
 * expansion state. Focus indication is rendered around the box when the
 * control has keyboard focus.
 *
 * @see Twistie
 * @since 3.0
 */
public class TreeNode : ToggleHyperlink {
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
        innerWidth = 10;
        innerHeight = 10;
    }
    protected void paint(PaintEvent e) {
        paintHyperlink(e.gc);
    }
    protected void paintHyperlink(GC gc) {
        Rectangle box = getBoxBounds(gc);
        gc.setForeground(getDisplay().getSystemColor(
                SWT.COLOR_WIDGET_NORMAL_SHADOW));
        gc.drawRectangle(box);
        gc.setForeground(getForeground());
        gc.drawLine(box.x + 2, box.y + 4, box.x + 6, box.y + 4);
        if (!isExpanded()) {
            gc.drawLine(box.x + 4, box.y + 2, box.x + 4, box.y + 6);
        }
        if (paintFocus && getSelection()) {
            gc.setForeground(getForeground());
            gc.drawFocus(box.x - 1, box.y - 1, box.width + 3, box.height + 3);
        }
    }
    private Rectangle getBoxBounds(GC gc) {
        int x = 1;
        int y = 0;
        gc.setFont(getFont());
        //int height = gc.getFontMetrics().getHeight();
        //y = height / 2 - 4;
        //y = Math.max(y, 0);
        y = 2;
        return new Rectangle(x, y, 8, 8);
    }
}
