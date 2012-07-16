/*******************************************************************************
 * Copyright (c) 2012 CWI
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *
 *   * Michael Steindorfer - Michael.Steindorfer@cwi.nl - CWI  
*******************************************************************************/
package org.rascalmpl.interpreter;

import java.util.EventObject;

public class InterpreterEvent extends EventObject {

	public enum Kind {
		CREATE,
		TERMINATE,
		RESUME,
		SUSPEND,
		IDLE
	}

	public enum Detail {
		UNSPECIFIED,
		CLIENT_REQUEST,
		STEP_INTO,
		STEP_OVER,
		STEP_END,
		BREAKPOINT
	}
	
	private final Kind kind;
	
	private final Detail detail;
	
	private Object data = null;

	public InterpreterEvent(Object eventSource, Kind kind) {
		this(eventSource, kind, Detail.UNSPECIFIED);
	}	
	
	public InterpreterEvent(Object eventSource, Kind kind, Detail detail) {
		super(eventSource);
		this.kind = kind;
		this.detail = detail;
	}
	
	public Kind getKind() {
		return kind;
	}

	public Detail getDetail() {
		return detail;
	}

	/**
	 * Sets this event's application defined data.
	 * 
	 * @param data application defined data
	 */
	public void setData(Object data) {
		this.data = data;
	}
	
	/**
	 * Returns this event's application defined data, or <code>null</code> if none
	 * 
	 * @return application defined data, or <code>null</code> if none
	 */
	public Object getData() {
		return data;
	}	
	
}
