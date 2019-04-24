CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "OraMail" AS
import java.util.Properties;
import java.util.Date;
import java.io.*;
import javax.mail.*;
import javax.mail.internet.*;
import javax.activation.*;
import java.sql.*;
import oracle.jdbc.driver.*;
import oracle.sql.*;
  
public class OraMail {
    public static int Send(
        String SMTPServer,
        String toList,
        String subject,
        oracle.sql.CLOB body,
        String sender,
        String replyTo,
        String ccList,
        String bccList,
        String headerExtra,
        oracle.sql.BLOB attachmentData,
        String attachmentType,
        String attachmentName,
        String[] errorMessage
        )
    {
        int returnCode = 0;

         //temporary code to fix a bug in 11.2.0.4 that will be patched by Oracle at a future date.
         MailcapCommandMap mc = (MailcapCommandMap)CommandMap.getDefaultCommandMap();
         mc.addMailcap("text/html;; x-java-content-handler=com.sun.mail.handlers.text_html");
         mc.addMailcap("text/xml;; x-java-content-handler=com.sun.mail.handlers.text_xml");
         mc.addMailcap("text/plain;; x-java-content-handler=com.sun.mail.handlers.text_plain");
         mc.addMailcap("multipart/*;; x-java-content-handler=com.sun.mail.handlers.multipart_mixed");
         mc.addMailcap("message/rfc822;; x-java-content-handler=com.sun.mail.handlers.message_rfc822");
         CommandMap.setDefaultCommandMap(mc);


        try {
            Properties props = System.getProperties();
            props.put("mail.smtp.host", SMTPServer);

            MimeMessage msg = new MimeMessage(Session.getDefaultInstance(props, null));

            msg.setFrom( new InternetAddress(sender));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toList));
            if (replyTo != null && replyTo.length() > 0)
                msg.setReplyTo(InternetAddress.parse(replyTo));
            if (ccList != null && ccList.length() > 0)
                msg.setRecipients(Message.RecipientType.CC, InternetAddress.parse(ccList));
            if (bccList != null && bccList.length() > 0)
                msg.setRecipients(Message.RecipientType.BCC, InternetAddress.parse(bccList));
            if (subject != null && subject.length() > 0)
                msg.setSubject(subject);
            else
                msg.setSubject("(no subject)");
            if (headerExtra != null)
                msg.addHeaderLine(headerExtra);
            msg.setSentDate(new Date());

            MimeMultipart mp = new MimeMultipart();

            if (body != null) {
                MimeBodyPart mbp1 = new MimeBodyPart();
                mbp1.setDisposition(Part.INLINE);
                mbp1.setDataHandler(new DataHandler(new CLOBDataSource(body, "text/html")));
                // now construct the multipart, adding the body part previously built
                mp.addBodyPart(mbp1);
            }
            else
                msg.setText("");
                
            if (attachmentData != null) {
                // if caller is passing binary data, construct a body part for the attachment
                MimeBodyPart mbp2 = new MimeBodyPart();
                mbp2.setDisposition(Part.ATTACHMENT);
                mbp2.setFileName(attachmentName);
                mbp2.setDataHandler(new DataHandler(new BLOBDataSource(attachmentData, attachmentType))
                );

                // now construct the multipart, adding the body part previously built
                mp.addBodyPart(mbp2);
            }

            msg.setContent(mp);
   
           Transport.send(msg);
           
           } catch (MessagingException msgException) {
               //msgException.printStackTrace();
               errorMessage[0] = msgException.toString();
               Exception anException = msgException.getNextException();
               if (anException != null)
                   errorMessage[0] = errorMessage[0] + "\n" + anException.toString();
               returnCode = 1;
             }
        return returnCode;
    } // End Send Class
     
    static class CLOBDataSource implements DataSource
    {
        private CLOB   data;
        private String type;
      
        CLOBDataSource(CLOB data, String type) {
            this.type = type;
            this.data = data;
        }
      
        public InputStream getInputStream() throws IOException {
            try {
                if (data == null)
                    throw new IOException("No data in parameter OraMail.body.");
                return data.getAsciiStream();
            } catch (SQLException e) {
                throw new IOException("Cannot get input stream from CLOB.");
              }
        }
        
        public OutputStream getOutputStream() throws IOException {
            throw new IOException("CLOBDataSource cannot support getOutputStream.");
        }

        public String getContentType() {
            return type;
        }

        public String getName() {
            return "CLOBDataSource";
        }
    } // End inner CLOBDataSource class

    static class BLOBDataSource implements DataSource
    {
        private BLOB   data;
        private String type;
      
        BLOBDataSource(BLOB data, String type) {
            this.type = type;
            this.data = data;
        }
      
        public InputStream getInputStream() throws IOException {
            try {
                if (data == null)
                    throw new IOException("No data in parameter OraMail.attachmentData.");
                return data.getBinaryStream();
            } catch (SQLException e) {
                throw new IOException("Cannot get binary input stream from BLOB.");
              }
        }
        
        public OutputStream getOutputStream() throws IOException {
            throw new IOException("BLOBDataSource cannot support getOutputStream.");
        }

        public String getContentType() {
            return type;
        }

        public String getName() {
            return "BLOBDataSource";
        }
    } // End inner BLOBDataSource class
     
  } // End of public class OraMail
/
