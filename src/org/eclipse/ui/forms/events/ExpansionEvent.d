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
module org.eclipse.ui.forms.events.ExpansionEvent;
import org.eclipse.swt.events.TypedEvent;
import java.lang.all;
/**
 * Notifies listeners when expandable controls change expansion state.
 *
 * @since 3.0
 */
public final class ExpansionEvent : TypedEvent {
    private static const long serialVersionUID = 6009335074727417445L;
    /**
     * Creates a new expansion ecent.
     *
     * @param obj
     *            event source
     * @param state
     *            the new expansion state
     */
    public this(Object obj, bool state) {
        super(obj);
        data = state ? Boolean.TRUE : Boolean.FALSE;
    }
    /**
     * Returns the new expansion state of the widget.
     *
     * @return <code>true</code> if the widget is now expaned, <code>false</code>
     *         otherwise.
     */
    public bool getState() {
        return data.opEquals(Boolean.TRUE) ? true : false;
    }
}
