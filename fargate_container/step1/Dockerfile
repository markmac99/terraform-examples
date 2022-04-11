FROM public.ecr.aws/lambda/python:3.8
RUN pip install flask
COPY *.py   ./

# CMD ["lambda_function.lambda_handler"]

ENTRYPOINT [ "python" ]
CMD ["app.py"]
