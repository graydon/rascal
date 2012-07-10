/*******************************************************************************
 * Copyright (c) 2009-2012 CWI
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:

 *   * Wietse Venema - wietsevenema@gmail.com - CWI
 *******************************************************************************/
package org.rascalmpl.library.cobra.util;

import java.io.PrintWriter;
import java.io.StringWriter;

import org.eclipse.imp.pdb.facts.IString;
import org.eclipse.imp.pdb.facts.IValue;
import org.eclipse.imp.pdb.facts.IValueFactory;
import org.rascalmpl.interpreter.Evaluator;
import org.rascalmpl.interpreter.IEvaluatorContext;
import org.rascalmpl.interpreter.utils.RuntimeExceptionFactory;

public class OutputLogger {

	private final IValueFactory vf;
	private StringWriter logger;


	public OutputLogger(IValueFactory vf) {
		this.vf = vf;
	}

	public IValue getLog(IEvaluatorContext e) {
		if (logger == null) {
			throw RuntimeExceptionFactory.permissionDenied(
					vf.string("getLog called before startLog"),
					e.getCurrentAST(), null);
		}
		IString result = vf.string(logger.getBuffer().toString());
		Evaluator eval = (Evaluator) e;
		eval.revertToDefaultWriters();
		logger = null;
		return result;
	}

	public void startLog(IEvaluatorContext e) {
		Evaluator eval = (Evaluator) e;
		logger = new StringWriter();
		eval.overrideDefaultWriters(new PrintWriter(logger), eval.getStdErr());
	}
}
