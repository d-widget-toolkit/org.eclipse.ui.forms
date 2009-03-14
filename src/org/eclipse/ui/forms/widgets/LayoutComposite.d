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
module org.eclipse.ui.forms.widgets.LayoutComposite;

import org.eclipse.ui.forms.widgets.TableWrapLayout;
import org.eclipse.ui.forms.widgets.ColumnLayout;

import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Layout;

import java.lang.all;
import java.util.Set;

/**
 * The class overrides default method for computing size in Composite by
 * accepting size returned from layout managers as-is. The default code accepts
 * width or height hint assuming it is correct. However, it is possible that
 * the computation using the provided width hint results in a real size that is
 * larger. This can result in wrapped text widgets being clipped, asking to
 * render in bounds narrower than the longest word.
 */
/* package */class LayoutComposite : Composite {
    public this(Composite parent, int style) {
        super(parent, style);
        setMenu(parent.getMenu());
    }
    public Point computeSize(int wHint, int hHint, bool changed) {
        Layout layout = getLayout();
        if (null !is cast(TableWrapLayout)layout )
            return (cast(TableWrapLayout) layout).computeSize(cast(Composite)this, wHint, hHint,
                    changed);
        if (null !is cast(ColumnLayout)layout )
            return (cast(ColumnLayout) layout).computeSize(cast(Composite)this, wHint, hHint,
                    changed);
        return super.computeSize(wHint, hHint, changed);
    }
}
