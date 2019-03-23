import json
import psycopg2
import datetime


def run():
    print('Start cronjob at %s' % str(datetime.datetime.now()))
    emails = get_bounced_emails()
    if len(emails) == 0:
        print('No new email logs was founded.')
        return

    sql = """INSERT INTO public.sisimai_output(
	rhost, lhost, senderdomain, alias, diagnosticcode, messageid, smtpagent, reason, feedbacktype, 
	softbounce, replycode, smtpcommand, timezoneoffset, catch, recipient, addresser, 
	"timestamp", token, destination, action, subject, listid, deliverystatus, diagnostictype)
	VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"""

    try:
        conn = psycopg2.connect(host="********", database="postfix", user="logwriter", password="**********")
        # create a new cursor
        cur = conn.cursor()
        # execute the INSERT statement
        cur.executemany(sql, emails)
        print('Inserted %d email logs to database.' % len(emails))
        # commit the changes to the database
        conn.commit()
        # close communication with the database
        cur.close()
        print('Cronjob completed  successfully.')
    except (Exception, psycopg2.DatabaseError) as error:
        print('Failed to complete cronjob, see error below:')
        print(error)
    finally:
        if conn is not None:
            conn.close()


def get_bounced_emails():
    emails = []
    try:
        conn = psycopg2.connect(host="********", database="postfix", user="logwriter", password="********")
        # create a new cursor
        cur = conn.cursor()
        # execute the INSERT statement
        with open('bounced_emails.json') as json_file:
            data = json.load(json_file)
            timestamps = [p['timestamp'] for p in data]
            if len(timestamps) == 0:
                return emails
            cur.execute("SELECT timestamp FROM public.sisimai_output WHERE  timestamp in %s", (tuple(timestamps),))
            rows = cur.fetchall()
            existing_timestamps = [row[0] for row in rows]
            for p in data:
                if p['timestamp'] in existing_timestamps:
                    continue

                email = (p['rhost'],
                         p['lhost'],
                         p['senderdomain'],
                         p['alias'],
                         p['diagnosticcode'],
                         p['messageid'],
                         p['smtpagent'],
                         p['reason'],
                         p['feedbacktype'] if (p['feedbacktype'] or p['feedbacktype'] == 0) else None,
                         p['softbounce'] if (p['softbounce'] or p['softbounce'] == 0) else None,
                         p['replycode'] if p['replycode'] or p['replycode'] == 0 else None,
                         p['smtpcommand'],
                         p['timezoneoffset'] if p['timezoneoffset'] or p['timezoneoffset'] == 0 else None,
                         p['catch'] if p['catch'] or p['catch'] == 0 else None,
                         p['recipient'],
                         p['addresser'],
                         p['timestamp'] if p['timestamp'] or p['timestamp'] == 0 else None,
                         p['token'],
                         p['destination'],
                         p['action'],
                         p['subject'],
                         p['listid'] if p['listid'] or p['listid'] == 0 else None,
                         p['deliverystatus'],
                         p['diagnostictype'],)
                emails.append(email)
        # commit the changes to the database
        conn.commit()
        # close communication with the database
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        print('Failed to complete cronjob, see error below:')
        print(error)
    finally:
        if conn is not None:
            conn.close()


    return emails


if __name__ == "__main__":
    run()

