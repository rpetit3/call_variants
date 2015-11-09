#! /usr/bin/env python
"""
Add decorator to time pipeline steps.

See the following links for more info:
    https://github.com/bunbun/ruffus/issues/15
    https://github.com/daler/pipeline-example/blob/master/pipeline-2/helpers.py

"""
import sys
import time


class time_job(object):

    """
    @time_job decorator.

    Wraps a function and prints elapsed time to standard out, or any other
    file-like object with a .write() method.
    """

    def __init__(self, stream=sys.stdout, new_stream=False):
        """ """
        self.stream = stream
        self.new_stream = new_stream

    def __call__(self, func):
        """ """
        def inner(*args, **kwargs):
            # Start the timer.
            start = time.time()
            # Run the decorated function.
            ret = func(*args, **kwargs)
            # Stop the timer.
            end = time.time()
            elapsed = end - start
            name = func.__name__

            runtime = "{0}\t{1:.4f}\n".format(name, elapsed)
            if type(self.stream) == str:
                if self.new_stream:
                    with open(self.stream, 'w') as log:
                        log.write(runtime)
                else:
                    with open(self.stream, 'a') as log:
                        log.write(runtime)
            else:
                self.stream.write(runtime)

            # Return the decorated function's return value.
            return ret

        inner.__name__ = func.__name__
        if hasattr(func, "pipeline_task"):
            inner.pipeline_task = func.pipeline_task
        return inner
