/*******************************************************************************
 * Copyright (c) 2000, 2005 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Chriss Gross (schtoo@schtoo.com) - fix for 61670
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/
module org.eclipse.ui.internal.forms.widgets.IHyperlinkSegment;

import org.eclipse.ui.internal.forms.widgets.IFocusSelectable;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Rectangle;

import java.lang.all;

public interface IHyperlinkSegment : IFocusSelectable {
    String getHref();
    String getText();
    void paintFocus(GC gc, Color bg, Color fg, bool selected, Rectangle repaintRegion);
    bool contains(int x, int y);
    bool intersects(Rectangle rect);
}
