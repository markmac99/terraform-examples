FROM public.ecr.aws/lambda/python:3.8
COPY *.py   ./
COPY requirements.txt ./
RUN pip install -r requirements.txt
EXPOSE 5000
ENTRYPOINT [ "python" ]
CMD ["app.py"]
