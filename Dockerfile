FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

RUN addgroup --system web2py \
    && adduser --system --ingroup web2py --home /home/web2py web2py

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

COPY --chown=web2py:web2py . .

RUN mkdir -p logs deposit \
    && chmod +x docker-entrypoint.sh \
    && chown -R web2py:web2py /app

USER web2py

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD python -c "import http.client, os; conn = http.client.HTTPConnection('127.0.0.1', int(os.environ.get('PORT', '8000')), timeout=4); conn.request('GET', '/'); status = conn.getresponse().status; raise SystemExit(0 if 200 <= status < 400 else 1)"

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["sh", "-c", "python anyserver.py -s gunicorn -i 0.0.0.0 -p ${PORT:-8000}"]
