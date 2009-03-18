/*******************************************************************************
 * Copyright (c) 2005, 2007 IBM Corporation and others.
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
module org.eclipse.ui.internal.forms.widgets.ControlSegment;

import org.eclipse.ui.internal.forms.widgets.ObjectSegment;
import org.eclipse.ui.internal.forms.widgets.IFocusSelectable;
import org.eclipse.ui.internal.forms.widgets.Locator;
import org.eclipse.ui.internal.forms.widgets.FormUtil;

import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;

import java.lang.all;
import java.util.Hashtable;
import java.util.Set;

public class ControlSegment : ObjectSegment, IFocusSelectable {


    private bool fill;
    private int width = SWT.DEFAULT;
    private int height = SWT.DEFAULT;

    // reimpl for interface
    Rectangle getBounds(){
        return super.getBounds();
    }

    public this() {
    }

    public void setFill(bool fill) {
        this.fill = fill;
    }

    public void setWidth(int width) {
        this.width = width;
    }

    public void setHeight(int height) {
        this.height = height;
    }

    public Control getControl(Hashtable resourceTable) {
        Object obj = resourceTable.get(getObjectId());
        if ( auto c = cast(Control)obj ) {
            if (!c.isDisposed())
                return c;
        }
        return null;
    }

    protected Point getObjectSize(Hashtable resourceTable, int wHint) {
        Control control = getControl(resourceTable);
        if (control is null)
            return new Point(0,0);
        int realWhint = FormUtil.getWidthHint(wHint, control);
        Point size = control.computeSize(realWhint, SWT.DEFAULT);
        if (realWhint !is SWT.DEFAULT && fill)
            size.x = Math.max(size.x, realWhint);
        if (width !is SWT.DEFAULT)
            size.x = width;
        if (height !is SWT.DEFAULT)
            size.y = height;
        return size;
    }

    public void layout(GC gc, int width, Locator loc, Hashtable resourceTable,
            bool selected) {
        super.layout(gc, width, loc, resourceTable, selected);
        Control control = getControl(resourceTable);
        if (control !is null)
            control.setBounds(getBounds());
    }

    public bool setFocus(Hashtable resourceTable, bool next) {
        Control c = getControl(resourceTable);
        if (c !is null) {
            return setFocus(c, next);
        }
        return false;
    }

    private bool setFocus(Control c, bool direction) {
        if (auto comp = cast(Composite)c ) {
            Control [] tabList = comp.getTabList();
            if (direction) {
                for (int i=0; i<tabList.length; i++) {
                    if (setFocus(tabList[i], direction))
                        return true;
                }
            }
            else {
                for (int i=tabList.length-1; i>=0; i--) {
                    if (setFocus(tabList[i], direction))
                        return true;
                }
            }
            if (!(null !is cast(Canvas)c ))
                return false;
        }
        return c.setFocus();
    }

    public bool isFocusSelectable(Hashtable resourceTable) {
        Control c = getControl(resourceTable);
        if (c !is null)
            return true;
        return false;
    }
}
