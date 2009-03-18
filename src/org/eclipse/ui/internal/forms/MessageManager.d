/*******************************************************************************
 * Copyright (c) 2007 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 ******************************************************************************/

module org.eclipse.ui.internal.forms.MessageManager;

import org.eclipse.ui.internal.forms.Messages;

import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.CLabel;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Label;
import org.eclipse.jface.dialogs.IMessageProvider;
import org.eclipse.jface.fieldassist.ControlDecoration;
import org.eclipse.jface.fieldassist.FieldDecoration;
import org.eclipse.jface.fieldassist.FieldDecorationRegistry;
import org.eclipse.ui.forms.IMessage;
import org.eclipse.ui.forms.IMessageManager;
import org.eclipse.ui.forms.IMessagePrefixProvider;
import org.eclipse.ui.forms.widgets.Hyperlink;
import org.eclipse.ui.forms.widgets.ScrolledForm;

import java.lang.all;
import java.util.Hashtable;
import java.util.Enumeration;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Set;

import tango.util.Convert;
import tango.text.Text;
import tango.io.model.IFile;

/**
 * @see IMessageManager
 */

public class MessageManager : IMessageManager {

    private static DefaultPrefixProvider DEFAULT_PREFIX_PROVIDER_;
    private static DefaultPrefixProvider DEFAULT_PREFIX_PROVIDER(){
        if( DEFAULT_PREFIX_PROVIDER_ is null ){
            synchronized(MessageManager.classinfo){
                if( DEFAULT_PREFIX_PROVIDER_ is null ){
                    DEFAULT_PREFIX_PROVIDER_ = new DefaultPrefixProvider();
                }
            }
        }
        return DEFAULT_PREFIX_PROVIDER_;
    }
    private ArrayList messages;
    private Hashtable decorators;
    private bool autoUpdate = true;
    private ScrolledForm scrolledForm;
    private IMessagePrefixProvider prefixProvider;
    private int decorationPosition = SWT.LEFT | SWT.BOTTOM;

    private static FieldDecoration standardError_;
    private static FieldDecoration standardError(){
        if( standardError_ is null ){
            synchronized(MessageManager.classinfo){
                if( standardError_ is null ){
                    standardError_ = FieldDecorationRegistry
                        .getDefault().getFieldDecoration(FieldDecorationRegistry.DEC_ERROR);
                }
            }
        }
        return standardError_;
    }

    private static FieldDecoration standardWarning_;
    private static FieldDecoration standardWarning(){
        if( standardWarning_ is null ){
            synchronized(MessageManager.classinfo){
                if( standardWarning_ is null ){
                    standardWarning_ = FieldDecorationRegistry
                        .getDefault().getFieldDecoration(FieldDecorationRegistry.DEC_WARNING);
                }
            }
        }
        return standardWarning_;
    }

    private static FieldDecoration standardInformation_;
    private static FieldDecoration standardInformation(){
        if( standardInformation_ is null ){
            synchronized(MessageManager.classinfo){
                if( standardInformation_ is null ){
                    standardInformation_ = FieldDecorationRegistry
                        .getDefault().getFieldDecoration(FieldDecorationRegistry.DEC_INFORMATION);
                }
            }
        }
        return standardInformation_;
    }

    private static String[] SINGLE_MESSAGE_SUMMARY_KEYS_;
    private static String[] SINGLE_MESSAGE_SUMMARY_KEYS(){
        if( SINGLE_MESSAGE_SUMMARY_KEYS_ is null ){
            synchronized(MessageManager.classinfo){
                if( SINGLE_MESSAGE_SUMMARY_KEYS_ is null ){
                    SINGLE_MESSAGE_SUMMARY_KEYS_ = [
                        Messages.MessageManager_sMessageSummary,
                        Messages.MessageManager_sMessageSummary,
                        Messages.MessageManager_sWarningSummary,
                        Messages.MessageManager_sErrorSummary ];
                }
            }
        }
        return SINGLE_MESSAGE_SUMMARY_KEYS_;
    }

    private static String[] MULTIPLE_MESSAGE_SUMMARY_KEYS_;
    private static String[] MULTIPLE_MESSAGE_SUMMARY_KEYS(){
        if( MULTIPLE_MESSAGE_SUMMARY_KEYS_ is null ){
            synchronized(MessageManager.classinfo){
                if( MULTIPLE_MESSAGE_SUMMARY_KEYS_ is null ){
                    MULTIPLE_MESSAGE_SUMMARY_KEYS_ = [
                        Messages.MessageManager_pMessageSummary,
                        Messages.MessageManager_pMessageSummary,
                        Messages.MessageManager_pWarningSummary,
                        Messages.MessageManager_pErrorSummary ];
                }
            }
        }
        return MULTIPLE_MESSAGE_SUMMARY_KEYS_;
    }

    static class Message : IMessage {
        Control control;
        Object data;
        Object key;
        String message;
        int type;
        String prefix;

        this(Object key, String message, int type, Object data) {
            this.key = key;
            this.message = message;
            this.type = type;
            this.data = data;
        }

        /*
         * (non-Javadoc)
         *
         * @see org.eclipse.jface.dialogs.IMessage#getKey()
         */
        public Object getKey() {
            return key;
        }

        /*
         * (non-Javadoc)
         *
         * @see org.eclipse.jface.dialogs.IMessageProvider#getMessage()
         */
        public String getMessage() {
            return message;
        }

        /*
         * (non-Javadoc)
         *
         * @see org.eclipse.jface.dialogs.IMessageProvider#getMessageType()
         */
        public int getMessageType() {
            return type;
        }

        /*
         * (non-Javadoc)
         *
         * @see org.eclipse.ui.forms.messages.IMessage#getControl()
         */
        public Control getControl() {
            return control;
        }

        /*
         * (non-Javadoc)
         *
         * @see org.eclipse.ui.forms.messages.IMessage#getData()
         */
        public Object getData() {
            return data;
        }

        /*
         * (non-Javadoc)
         *
         * @see org.eclipse.ui.forms.messages.IMessage#getPrefix()
         */
        public String getPrefix() {
            return prefix;
        }
    }

    static class DefaultPrefixProvider : IMessagePrefixProvider {

        public String getPrefix(Control c) {
            Composite parent = c.getParent();
            Control[] siblings = parent.getChildren();
            for (int i = 0; i < siblings.length; i++) {
                if (siblings[i] is c) {
                    // this is us - go backward until you hit
                    // a label-like widget
                    for (int j = i - 1; j >= 0; j--) {
                        Control label = siblings[j];
                        String ltext = null;
                        if ( auto l = cast(Label)label ) {
                            ltext = l.getText();
                        } else if ( auto hl = cast(Hyperlink)label ) {
                            ltext = hl.getText();
                        } else if ( auto cl = cast(CLabel)label ) {
                            ltext = cl.getText();
                        }
                        if (ltext !is null) {
                            if (!ltext.endsWith(":")) //$NON-NLS-1$
                                return ltext ~ ": "; //$NON-NLS-1$
                            return ltext ~ " "; //$NON-NLS-1$
                        }
                    }
                    break;
                }
            }
            return null;
        }
    }

    class ControlDecorator {
        private ControlDecoration decoration;
        private ArrayList controlMessages;
        private String prefix;

        this(Control control) {
            controlMessages = new ArrayList();
            this.decoration = new ControlDecoration(control, decorationPosition, scrolledForm.getBody());
        }

        public bool isDisposed() {
            return decoration.getControl() is null;
        }

        void updatePrefix() {
            prefix = null;
        }

        void updatePosition() {
            Control control = decoration.getControl();
            decoration.dispose();
            this.decoration = new ControlDecoration(control, decorationPosition, scrolledForm.getBody());
            update();
        }

        String getPrefix() {
            if (prefix is null)
                createPrefix();
            return prefix;
        }

        private void createPrefix() {
            if (prefixProvider is null) {
                prefix = ""; //$NON-NLS-1$
                return;
            }
            prefix = prefixProvider.getPrefix(decoration.getControl());
            if (prefix is null)
                // make a prefix anyway
                prefix = ""; //$NON-NLS-1$
        }

        void addAll(ArrayList target) {
            target.addAll(controlMessages);
        }

        void addMessage(Object key, String text, Object data, int type) {
            Message message = this.outer.addMessage(getPrefix(), key,
                    text, data, type, controlMessages);
            message.control = decoration.getControl();
            if (isAutoUpdate())
                update();
        }

        bool removeMessage(Object key) {
            Message message = findMessage(key, controlMessages);
            if (message !is null) {
                controlMessages.remove(message);
                if (isAutoUpdate())
                    update();
            }
            return message !is null;
        }

        bool removeMessages() {
            if (controlMessages.isEmpty())
                return false;
            controlMessages.clear();
            if (isAutoUpdate())
                update();
            return true;
        }

        public void update() {
            if (controlMessages.isEmpty()) {
                decoration.setDescriptionText(null);
                decoration.hide();
            } else {
                ArrayList peers = createPeers(controlMessages);
                int type = (cast(IMessage) peers.get(0)).getMessageType();
                String description = createDetails(createPeers(peers), true);
                if (type is IMessageProvider.ERROR)
                    decoration.setImage(standardError.getImage());
                else if (type is IMessageProvider.WARNING)
                    decoration.setImage(standardWarning.getImage());
                else if (type is IMessageProvider.INFORMATION)
                    decoration.setImage(standardInformation.getImage());
                decoration.setDescriptionText(description);
                decoration.show();
            }
        }
    }

    /**
     * Creates a new instance of the message manager that will work with the
     * provided form.
     *
     * @param scrolledForm
     *            the form to control
     */
    public this(ScrolledForm scrolledForm) {
        prefixProvider = DEFAULT_PREFIX_PROVIDER;
        messages = new ArrayList();
        decorators = new Hashtable();
        this.scrolledForm = scrolledForm;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#addMessage(java.lang.Object,
     *      java.lang.String, int)
     */
    public void addMessage(Object key, String messageText, Object data, int type) {
        addMessage(null, key, messageText, data, type, messages);
        if (isAutoUpdate())
            updateForm();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#addMessage(java.lang.Object,
     *      java.lang.String, int, org.eclipse.swt.widgets.Control)
     */
    public void addMessage(Object key, String messageText, Object data,
            int type, Control control) {
        ControlDecorator dec = cast(ControlDecorator) decorators.get(control);

        if (dec is null) {
            dec = new ControlDecorator(control);
            decorators.put(control, dec);
        }
        dec.addMessage(key, messageText, data, type);
        if (isAutoUpdate())
            updateForm();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#removeMessage(java.lang.Object)
     */
    public void removeMessage(Object key) {
        Message message = findMessage(key, messages);
        if (message !is null) {
            messages.remove(message);
            if (isAutoUpdate())
                updateForm();
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#removeMessages()
     */
    public void removeMessages() {
        if (!messages.isEmpty()) {
            messages.clear();
            if (isAutoUpdate())
                updateForm();
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#removeMessage(java.lang.Object,
     *      org.eclipse.swt.widgets.Control)
     */
    public void removeMessage(Object key, Control control) {
        ControlDecorator dec = cast(ControlDecorator) decorators.get(control);
        if (dec is null)
            return;
        if (dec.removeMessage(key))
            if (isAutoUpdate())
                updateForm();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#removeMessages(org.eclipse.swt.widgets.Control)
     */
    public void removeMessages(Control control) {
        ControlDecorator dec = cast(ControlDecorator) decorators.get(control);
        if (dec !is null) {
            if (dec.removeMessages()) {
                if (isAutoUpdate())
                    updateForm();
            }
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#removeAllMessages()
     */
    public void removeAllMessages() {
        bool needsUpdate = false;
        for (Enumeration enm = decorators.elements(); enm.hasMoreElements();) {
            ControlDecorator control = cast(ControlDecorator) enm.nextElement();
            if (control.removeMessages())
                needsUpdate = true;
        }
        if (!messages.isEmpty()) {
            messages.clear();
            needsUpdate = true;
        }
        if (needsUpdate && isAutoUpdate())
            updateForm();
    }

    /*
     * Adds the message if it does not already exist in the provided list.
     */

    private Message addMessage(String prefix, Object key, String messageText,
            Object data, int type, ArrayList list) {
        Message message = findMessage(key, list);
        if (message is null) {
            message = new Message(key, messageText, type, data);
            message.prefix = prefix;
            list.add(message);
        } else {
            message.message = messageText;
            message.type = type;
            message.data = data;
        }
        return message;
    }

    /*
     * Finds the message with the provided key in the provided list.
     */

    private Message findMessage(Object key, ArrayList list) {
        for (int i = 0; i < list.size(); i++) {
            Message message = cast(Message) list.get(i);
            if (message.getKey().opEquals(key))
                return message;
        }
        return null;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#update()
     */
    public void update() {
        // Update decorations
        for (Iterator iter = decorators.values().iterator(); iter.hasNext();) {
            ControlDecorator dec = cast(ControlDecorator) iter.next();
            dec.update();
        }
        // Update the form
        updateForm();
    }

    /*
     * Updates the container by rolling the messages up from the controls.
     */

    private void updateForm() {
        ArrayList mergedList = new ArrayList();
        mergedList.addAll(messages);
        for (Enumeration enm = decorators.elements(); enm.hasMoreElements();) {
            ControlDecorator dec = cast(ControlDecorator) enm.nextElement();
            dec.addAll(mergedList);
        }
        update(mergedList);
    }

    private void update(ArrayList mergedList) {
        pruneControlDecorators();
        if (scrolledForm.getForm().getHead().getBounds().height is 0 || mergedList.isEmpty() || mergedList is null) {
            scrolledForm.setMessage(null, IMessageProvider.NONE);
            return;
        }
        ArrayList peers = createPeers(mergedList);
        int maxType = (cast(IMessage) peers.get(0)).getMessageType();
        String messageText;
        IMessage[] array = arraycast!(IMessage)( peers
                .toArray());
        if (peers.size() is 1 && (cast(Message) peers.get(0)).prefix is null) {
            // a single message
            IMessage message = cast(IMessage) peers.get(0);
            messageText = message.getMessage();
            scrolledForm.setMessage(messageText, maxType, array);
        } else {
            // show a summary message for the message
            // and list of errors for the details
            if (peers.size() > 1)
                messageText = Messages.bind(
                        MULTIPLE_MESSAGE_SUMMARY_KEYS[maxType],
                        [ to!(String)(peers.size()) ]); //$NON-NLS-1$
            else
                messageText = SINGLE_MESSAGE_SUMMARY_KEYS[maxType];
            scrolledForm.setMessage(messageText, maxType, array);
        }
    }

    private static String getFullMessage(IMessage message) {
        if (message.getPrefix() is null)
            return message.getMessage();
        return message.getPrefix() ~ message.getMessage();
    }

    private ArrayList createPeers(ArrayList messages) {
        ArrayList peers = new ArrayList();
        int maxType = 0;
        for (int i = 0; i < messages.size(); i++) {
            Message message = cast(Message) messages.get(i);
            if (message.type > maxType) {
                peers.clear();
                maxType = message.type;
            }
            if (message.type is maxType)
                peers.add(message);
        }
        return peers;
    }

    private String createDetails(ArrayList messages, bool excludePrefix) {
        auto txt = new tango.text.Text.Text!(char);

        for (int i = 0; i < messages.size(); i++) {
            if (i > 0)
                txt.append( FileConst.NewlineString );
            IMessage m = cast(IMessage) messages.get(i);
            txt.append(excludePrefix ? m.getMessage() : getFullMessage(m));
        }
        return txt.toString();
    }

    public static String createDetails(IMessage[] messages) {
        if (messages is null || messages.length is 0)
            return null;
        auto txt = new tango.text.Text.Text!(char);

        for (int i = 0; i < messages.length; i++) {
            if (i > 0)
                txt.append( FileConst.NewlineString );
            txt.append(getFullMessage(messages[i]));
        }
        return txt.toString();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#createSummary(org.eclipse.ui.forms.IMessage[])
     */
    public String createSummary(IMessage[] messages) {
        return createDetails(messages);
    }

    private void pruneControlDecorators() {
        for (Iterator iter = decorators.values().iterator(); iter.hasNext();) {
            ControlDecorator dec = cast(ControlDecorator) iter.next();
            if (dec.isDisposed())
                iter.remove();
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#getMessagePrefixProvider()
     */
    public IMessagePrefixProvider getMessagePrefixProvider() {
        return prefixProvider;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#setMessagePrefixProvider(org.eclipse.ui.forms.IMessagePrefixProvider)
     */
    public void setMessagePrefixProvider(IMessagePrefixProvider provider) {
        this.prefixProvider = provider;
        for (Iterator iter = decorators.values().iterator(); iter.hasNext();) {
            ControlDecorator dec = cast(ControlDecorator) iter.next();
            dec.updatePrefix();
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#getDecorationPosition()
     */
    public int getDecorationPosition() {
        return decorationPosition;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#setDecorationPosition(int)
     */
    public void setDecorationPosition(int position) {
        this.decorationPosition = position;
        for (Iterator iter = decorators.values().iterator(); iter.hasNext();) {
            ControlDecorator dec = cast(ControlDecorator) iter.next();
            dec.updatePosition();
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#isAutoUpdate()
     */
    public bool isAutoUpdate() {
        return autoUpdate;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IMessageManager#setAutoUpdate(bool)
     */
    public void setAutoUpdate(bool autoUpdate) {
        bool needsUpdate = !this.autoUpdate && autoUpdate;
        this.autoUpdate = autoUpdate;
        if (needsUpdate)
            update();
    }
}
